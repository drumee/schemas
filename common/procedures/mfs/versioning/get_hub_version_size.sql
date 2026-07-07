DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_version_size`$
CREATE PROCEDURE `get_hub_version_size`()
BEGIN
  -- Per-hub versioning footprint, split by active vs history. Summed across the
  -- org's hubs by versionRetentionWorker to populate the "Versioning Impact"
  -- card (history_bytes cached into organisation.metadata).
  SELECT
    COALESCE(SUM(IF(is_active = 0, filesize, 0)), 0) AS history_bytes,
    COALESCE(SUM(IF(is_active = 1, filesize, 0)), 0) AS active_bytes
  FROM file_version;
END$

DELIMITER ;
