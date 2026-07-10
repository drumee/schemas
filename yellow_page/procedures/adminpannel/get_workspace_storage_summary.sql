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
  SELECT CAST(IFNULL(JSON_VALUE(q.quota, '$.disk'), 0) AS DOUBLE)
    FROM yp.quota q WHERE q.domain_id = _domain_id LIMIT 1
    INTO _org_disk;
  SET _org_disk = IFNULL(_org_disk, 0);

  DROP TEMPORARY TABLE IF EXISTS _ws_summary;
  CREATE TEMPORARY TABLE _ws_summary (
    hub_id VARCHAR(16) NOT NULL PRIMARY KEY,
    hub_name VARCHAR(255),
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    quota_bytes DOUBLE NOT NULL DEFAULT 0,
    reclaim_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    reclaim_files INT UNSIGNED NOT NULL DEFAULT 0
  );

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
    SET _quota = NULL;
    SELECT quota FROM yp.quota WHERE payer_id = _owner_id LIMIT 1 INTO _quota;
    IF _quota IS NULL AND _domain_id > 1 THEN
      SELECT quota FROM yp.quota WHERE domain_id = _domain_id LIMIT 1 INTO _quota;
    END IF;
    IF _quota IS NULL THEN
      SELECT JSON_QUERY(profile, '$.quota') FROM yp.drumate
        WHERE id = _owner_id LIMIT 1 INTO _quota;
    END IF;
    SET _q_disk = CAST(IFNULL(JSON_VALUE(_quota, '$.disk'), 0) AS DOUBLE);
    SET _q_hub  = CAST(IFNULL(JSON_VALUE(_quota, '$.hub_disk'), _q_disk) AS DOUBLE);
    IF _q_hub IS NULL OR _q_hub <= 0 THEN SET _q_hub = _org_disk; END IF;

    UPDATE _ws_summary
    SET used_bytes = _used,
        quota_bytes = IFNULL(_q_hub, 0),
        reclaim_bytes = _reclaim_bytes,
        reclaim_files = _reclaim_files
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
