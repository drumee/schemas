DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_storage_stats`$
CREATE PROCEDURE `get_hub_storage_stats`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _dom_id INT(11) UNSIGNED DEFAULT 0;
  DECLARE _owner_id VARCHAR(16) DEFAULT NULL;
  DECLARE _org_id VARCHAR(16) DEFAULT NULL;
  DECLARE _quota_bytes BIGINT UNSIGNED DEFAULT 0;
  DECLARE _domain_used BIGINT UNSIGNED DEFAULT 0;
  DECLARE _hub_used BIGINT UNSIGNED DEFAULT 0;
  DECLARE _doc_bytes BIGINT UNSIGNED DEFAULT 0;
  DECLARE _media_bytes BIGINT UNSIGNED DEFAULT 0;
  DECLARE _other_bytes BIGINT DEFAULT 0;

  -- Get dom_id for this hub
  SELECT dom_id
  INTO _dom_id
  FROM yp.entity
  WHERE id = _hub_id;

  SELECT owner_id INTO _owner_id FROM yp.hub WHERE id = _hub_id LIMIT 1;

  -- CAPACITY, resolved DETERMINISTICALLY.
  --
  -- This used to be `SELECT disk FROM yp.quota WHERE domain_id=_dom_id LIMIT 1`
  -- with no ORDER BY and no payer filter. A domain routinely holds SEVERAL rows
  -- — org_provision re-keys a payer's personal row onto the new org domain, and
  -- domain 1 holds one row per solo payer (12 on stage) — so that query returned
  -- an ARBITRARY row. Measured on stage: for a solo user's hub it reported
  -- 100 GB belonging to an unrelated user as "the domain quota". Adding a
  -- claim-reward row, whose $.disk is the 2^63-1 unlimited sentinel, put a
  -- 9.2 EB answer into the same lottery.
  --
  -- The tiers now mirror utils/disk_limit.sql, which is what actually ENFORCES:
  --   1. the ORGANISATION's own row (payer_id = organisation.id) — the shared
  --      allowance every member of an org domain is capped by
  --   2. otherwise the hub OWNER's personal row, skipping an expired reward
  --   3. otherwise the seeded free fallback
  -- so the panel and enforcement can no longer disagree about the number.
  SELECT o.id INTO _org_id FROM yp.organisation o
   WHERE o.domain_id = _dom_id LIMIT 1;

  IF _org_id IS NOT NULL THEN
    SELECT COALESCE(q.disk, 0) INTO _quota_bytes FROM yp.quota q
     WHERE q.domain_id = _dom_id AND q.payer_id = _org_id LIMIT 1;
  END IF;

  IF (_quota_bytes IS NULL OR _quota_bytes = 0) AND _owner_id IS NOT NULL THEN
    SELECT COALESCE(q.disk, 0) INTO _quota_bytes FROM yp.quota q
     WHERE q.payer_id = _owner_id
       AND (IFNULL(q.source, 'free') <> 'reward'
            OR IFNULL(q.period_end, 0) = 0
            OR q.period_end > UNIX_TIMESTAMP())
     LIMIT 1;
  END IF;

  IF _quota_bytes IS NULL OR _quota_bytes = 0 THEN
    SELECT COALESCE(q.disk, 0) INTO _quota_bytes FROM yp.quota q
     WHERE q.payer_id = 'ffffffffffffffff' AND q.domain_id = 1 LIMIT 1;
  END IF;
  SET _quota_bytes = COALESCE(_quota_bytes, 0);

  -- USAGE against that capacity.
  --
  -- quota_usage is keyed by domain and only written for domain_id > 1 (see the
  -- disk_usage_sync_quota_cache trigger), so for a solo user's hub the lookup
  -- found nothing and _domain_used stayed 0 — the panel showed 0% used of a
  -- capacity that belonged to someone else. When the capacity is the OWNER's,
  -- the usage has to be the owner's too: summed from yp.disk_usage over their
  -- hubs plus their own desk, the same pair directory/my_disk_limit.sql adds up.
  IF _org_id IS NOT NULL THEN
    SELECT COALESCE(cached_usage, 0)
    INTO _domain_used
    FROM yp.quota_usage
    WHERE domain_id = _dom_id
    LIMIT 1;
  ELSEIF _owner_id IS NOT NULL THEN
    SELECT COALESCE(
      (SELECT SUM(du.size) FROM yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id WHERE h.owner_id = _owner_id), 0)
    + COALESCE(
      (SELECT SUM(du.size) FROM yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id WHERE d.id = _owner_id), 0)
    INTO _domain_used;
  END IF;
  SET _domain_used = COALESCE(_domain_used, 0);

  -- Hub-level used (all non-system files in this hub's media table)
  SELECT COALESCE(SUM(filesize), 0)
  INTO _hub_used
  FROM media
  WHERE status NOT IN ('hidden', 'deleted')
    AND category NOT IN ('folder', 'hub', 'root');

  -- Documents breakdown (hub-level)
  SELECT COALESCE(SUM(filesize), 0)
  INTO _doc_bytes
  FROM media
  WHERE status NOT IN ('hidden', 'deleted')
    AND category IN ('document', 'pdf', 'note', 'sheet', 'slide');

  -- Media Assets breakdown (hub-level)
  SELECT COALESCE(SUM(filesize), 0)
  INTO _media_bytes
  FROM media
  WHERE status NOT IN ('hidden', 'deleted')
    AND category IN ('image', 'video', 'audio');

  -- Other
  SET _other_bytes = _hub_used - _doc_bytes - _media_bytes;
  IF _other_bytes < 0 THEN SET _other_bytes = 0; END IF;

  SELECT
    _hub_id AS hub_id,
    _dom_id AS domain_id,
    -- Domain-level capacity (for TOTAL HUB CAPACITY display)
    _quota_bytes AS quota_bytes,
    _domain_used AS domain_used_bytes,
    IF(_quota_bytes > 0,
      ROUND((_domain_used / _quota_bytes) * 100, 1),
      0) AS domain_usage_pct,
    -- Hub-level breakdown (for consumption trend chart)
    _hub_used AS hub_used_bytes,
    _doc_bytes AS documents_bytes,
    _media_bytes AS media_bytes,
    _other_bytes AS other_bytes,
    IF(_quota_bytes > 0,
      _quota_bytes - _domain_used,
      0) AS available_bytes,
    -- Low storage alert: domain usage >= 90%
    IF(_quota_bytes > 0
      AND (_domain_used / _quota_bytes) >= 0.9,
      1, 0) AS low_storage_alert;
END$

DELIMITER ;