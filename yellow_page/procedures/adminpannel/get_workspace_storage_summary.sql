DELIMITER $

DROP PROCEDURE IF EXISTS `get_workspace_storage_summary`$
CREATE PROCEDURE `get_workspace_storage_summary`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _finished INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16);
  DECLARE _used BIGINT UNSIGNED DEFAULT 0;
  DECLARE _quota JSON;
  DECLARE _q_disk DOUBLE DEFAULT 0;
  DECLARE _q_hub DOUBLE DEFAULT 0;
  DECLARE _org_disk DOUBLE DEFAULT 0;
  DECLARE _has_fv INT DEFAULT 0;
  DECLARE _reclaim_bytes BIGINT UNSIGNED DEFAULT 0;
  DECLARE _reclaim_files INT UNSIGNED DEFAULT 0;
  DECLARE _stale_bytes BIGINT UNSIGNED DEFAULT 0;
  DECLARE _stale_files INT UNSIGNED DEFAULT 0;
  -- "Stale" = not modified in the last 90 days; feeds the Delete-Files
  -- candidates (files an admin may want to move to Trash).
  DECLARE _stale_cutoff INT UNSIGNED DEFAULT 0;

  DECLARE hub_cursor CURSOR FOR
    SELECT e.id, e.db_name, h.owner_id
    FROM yp.entity e
    LEFT JOIN yp.hub h ON h.id = e.id
    WHERE e.dom_id = _domain_id
      AND e.type = 'hub'
      AND e.status = 'active'
      AND e.db_name IS NOT NULL
      AND e.db_name != '';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;

  -- Domain-level bound used when the hub owner has no hub_disk entitlement.
  --
  -- Resolved as the ORGANISATION's own row, not an unordered LIMIT 1 over the
  -- domain. A domain holds several rows — org_provision re-keys a payer's
  -- personal row onto the new org domain, and domain 1 holds one per solo payer
  -- — so the old query picked an arbitrary one and could report an unrelated
  -- user's allowance as the domain bound. Adding claim-reward rows, whose
  -- $.disk is the 2^63-1 unlimited sentinel, made a 9.2 EB answer possible in
  -- the same lottery. Same tier-1 test as get_org_quota and disk_limit.
  -- Scalar subquery, not `SELECT ... INTO`: the INNER JOIN matches nothing for a
  -- domain with no organisation, which would raise NOT FOUND into the cursor's
  -- handler. Harmless here only because _finished is reset before OPEN below —
  -- and depending on that is how the same mistake reached the loop body.
  SET _org_disk = (
    SELECT CAST(IFNULL(JSON_VALUE(q.quota, '$.disk'), 0) AS DOUBLE)
      FROM yp.quota q
     INNER JOIN yp.organisation o
        ON o.domain_id = q.domain_id AND o.id = q.payer_id
     WHERE q.domain_id = _domain_id LIMIT 1);
  -- No organisation (domain 1 / legacy): there is no shared domain allowance to
  -- fall back on, so 0 — which the per-hub logic below already reads as
  -- "unbounded at the domain level" and leaves the owner's own tier to decide.
  SET _org_disk = IFNULL(_org_disk, 0);

  DROP TEMPORARY TABLE IF EXISTS _ws_summary;
  CREATE TEMPORARY TABLE _ws_summary (
    hub_id VARCHAR(16) NOT NULL PRIMARY KEY,
    hub_name VARCHAR(255),
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    quota_bytes DOUBLE NOT NULL DEFAULT 0,
    reclaim_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    reclaim_files INT UNSIGNED NOT NULL DEFAULT 0,
    stale_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    stale_files INT UNSIGNED NOT NULL DEFAULT 0
  );

  SET _stale_cutoff = UNIX_TIMESTAMP() - 90 * 86400;

  INSERT INTO _ws_summary (hub_id, hub_name)
  SELECT e.id, IFNULL(IFNULL(e.ident, h.name), h.hubname)
  FROM yp.entity e
  LEFT JOIN yp.hub h ON h.id = e.id
  WHERE e.dom_id = _domain_id
    AND e.type = 'hub'
    AND e.status = 'active';

  SET _finished = 0;
  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _hub_id, _db_name, _owner_id;
    IF _finished = 1 THEN
      LEAVE hub_loop;
    END IF;

    -- Live usage (same filter as get_org_storage_stats).
    SET _used = 0;
    SET @sql = CONCAT(
      'SELECT COALESCE(SUM(m.filesize), 0) INTO @ws_used_bytes ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _used = COALESCE(@ws_used_bytes, 0);

    -- Stale files (no publish/upload activity in 90 days) — Delete-Files
    -- candidates. media has no mtime; publish_time falls back to upload_time.
    SET @sql = CONCAT(
      'SELECT COALESCE(SUM(m.filesize), 0), COUNT(*) ',
      'INTO @ws_stale_bytes, @ws_stale_files ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'') ',
      'AND COALESCE(NULLIF(m.publish_time, 0), m.upload_time) > 0 ',
      'AND COALESCE(NULLIF(m.publish_time, 0), m.upload_time) < ', _stale_cutoff
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _stale_bytes = COALESCE(@ws_stale_bytes, 0);
    SET _stale_files = COALESCE(@ws_stale_files, 0);

    -- Delete-candidate estimate = superseded version history (is_active=0)
    -- in the hub's file_version table. Guarded: hubs created before the
    -- versioning feature may not have the table yet.
    SET _reclaim_bytes = 0;
    SET _reclaim_files = 0;
    SELECT COUNT(*) INTO _has_fv
      FROM information_schema.tables
      WHERE table_schema = _db_name AND table_name = 'file_version';
    IF _has_fv > 0 THEN
      SET @sql = CONCAT(
        'SELECT COALESCE(SUM(filesize), 0), COUNT(DISTINCT nid) ',
        'INTO @ws_reclaim_bytes, @ws_reclaim_files ',
        'FROM `', _db_name, '`.file_version WHERE is_active = 0'
      );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SET _reclaim_bytes = COALESCE(@ws_reclaim_bytes, 0);
      SET _reclaim_files = COALESCE(@ws_reclaim_files, 0);
    END IF;

    -- Owner entitlement, mirroring utils/disk_free.sql tiers:
    -- payer quota -> domain quota -> legacy drumate profile quota.
    -- hub_disk falls back to disk; 'Infinity'/non-numeric casts to 0 and is
    -- treated as unbounded -> the domain disk becomes the visual bound.
    -- EVERY TIER IS A SCALAR SUBQUERY, NOT `SELECT ... INTO`.
    --
    -- This block runs inside the hub cursor loop, and the loop's
    -- `CONTINUE HANDLER FOR NOT FOUND` is armed for the FETCH. A
    -- `SELECT ... INTO` that matches no row raises NOT FOUND too, so it fired
    -- that handler, set _finished = 1 and silently ENDED THE LOOP — every
    -- remaining workspace vanished from the console with no error.
    --
    -- The hazard predates this change (an owner with no payer row triggered it),
    -- but the reward-expiry guard below made it routine: it is written to match
    -- zero rows, which is exactly the case that killed the loop. Caught in the
    -- scratch run, where an expired reward on the FIRST hub dropped the second
    -- hub from the result entirely.
    --
    -- A scalar subquery yields NULL for a missing row instead, which is what
    -- each IF below is already testing for.
    --
    -- Tier 1 skips an EXPIRED claim-reward entitlement, so the console falls
    -- through exactly as enforcement does. Without it the reward's 2^63-1 was
    -- still reported as quota_bytes after the term ended: usage_pct rounded to 0
    -- and `status` read 'healthy' forever, for a user whose uploads were being
    -- refused. Scoped to source='reward' because a Stripe row's period_end is
    -- informational, and NULL means "no expiry" alongside 0.
    SET _quota = (
      SELECT quota FROM yp.quota
       WHERE payer_id = _owner_id
         AND (IFNULL(source, 'free') <> 'reward'
              OR IFNULL(period_end, 0) = 0
              OR period_end > UNIX_TIMESTAMP())
       LIMIT 1);
    IF _quota IS NULL AND _domain_id > 1 THEN
      SET _quota = (SELECT q.quota FROM yp.quota q
                     INNER JOIN yp.organisation o
                        ON o.domain_id = q.domain_id AND o.id = q.payer_id
                     WHERE q.domain_id = _domain_id LIMIT 1);
    END IF;
    IF _quota IS NULL THEN
      SET _quota = (SELECT JSON_QUERY(profile, '$.quota') FROM yp.drumate
                     WHERE id = _owner_id LIMIT 1);
    END IF;
    -- Tier 4: the seeded free fallback, which utils/disk_limit.sql has and this
    -- cascade was missing. Without it an owner with no personal row resolved to
    -- quota_bytes 0, so usage_pct was 0 and `status` read 'healthy' for a user
    -- enforcement caps at 5 GB — the same disagreement tier 1's guard exists to
    -- prevent, reached by a different route. An expired reward lands here now.
    IF _quota IS NULL THEN
      SET _quota = (SELECT quota FROM yp.quota
                     WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1 LIMIT 1);
    END IF;
    SET _q_disk = CAST(IFNULL(JSON_VALUE(_quota, '$.disk'), 0) AS DOUBLE);
    SET _q_hub  = CAST(IFNULL(JSON_VALUE(_quota, '$.hub_disk'), _q_disk) AS DOUBLE);
    IF _q_hub IS NULL OR _q_hub <= 0 THEN SET _q_hub = _org_disk; END IF;

    UPDATE _ws_summary
    SET used_bytes = _used,
        quota_bytes = IFNULL(_q_hub, 0),
        reclaim_bytes = _reclaim_bytes,
        reclaim_files = _reclaim_files,
        stale_bytes = _stale_bytes,
        stale_files = _stale_files
    WHERE hub_id = _hub_id;
  END LOOP hub_loop;
  CLOSE hub_cursor;

  -- Thresholds: critical >= 90%, warning >= 75%, else healthy.
  SELECT
    hub_id,
    hub_name,
    used_bytes,
    quota_bytes,
    reclaim_bytes,
    reclaim_files,
    stale_bytes,
    stale_files,
    IF(quota_bytes > 0, ROUND(used_bytes / quota_bytes * 100, 1), 0) AS usage_pct,
    CASE
      WHEN quota_bytes > 0 AND used_bytes / quota_bytes >= 0.90 THEN 'critical'
      WHEN quota_bytes > 0 AND used_bytes / quota_bytes >= 0.75 THEN 'warning'
      ELSE 'healthy'
    END AS status
  FROM _ws_summary
  ORDER BY used_bytes DESC;

  DROP TEMPORARY TABLE IF EXISTS _ws_summary;
END$

DELIMITER ;
