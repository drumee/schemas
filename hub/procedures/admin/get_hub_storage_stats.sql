DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_storage_stats`$
CREATE PROCEDURE `get_hub_storage_stats`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _dom_id INT(11) UNSIGNED DEFAULT 0;
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

  -- Total quota for the domain (bytes)
  SELECT COALESCE(disk, 0)
  INTO _quota_bytes
  FROM yp.quota
  WHERE domain_id = _dom_id
  LIMIT 1;

  -- Domain-level total used (cached)
  SELECT COALESCE(cached_usage, 0)
  INTO _domain_used
  FROM yp.quota_usage
  WHERE domain_id = _dom_id
  LIMIT 1;

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