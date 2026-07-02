DELIMITER $

DROP PROCEDURE IF EXISTS `organisation_cache_version_history`$
CREATE PROCEDURE `organisation_cache_version_history`(
  IN _id VARCHAR(16),
  IN _bytes BIGINT UNSIGNED
)
BEGIN
  -- versionRetentionWorker caches the org-wide old-version footprint here so the
  -- Storage "Versioning Impact" card can render it without a cross-hub scan on
  -- every page load. Refreshed each worker run.
  UPDATE organisation
  SET metadata = JSON_SET(
    IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
    '$.version_history_bytes', _bytes
  )
  WHERE id = _id;
END$

DELIMITER ;
