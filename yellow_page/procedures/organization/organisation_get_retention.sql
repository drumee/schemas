DELIMITER $

DROP PROCEDURE IF EXISTS `organisation_get_retention`$
CREATE PROCEDURE `organisation_get_retention`(
  IN _domain_id INT
)
BEGIN
  -- Reads the org-wide versioning retention policy from organisation.metadata.
  -- Defaults (30 days, toggles off) when the keys were never written. The
  -- version_history_bytes value is a cache refreshed by versionRetentionWorker
  -- for the "Versioning Impact" card (0 until the first worker run).
  SELECT
    CAST(COALESCE(JSON_VALUE(m, '$.version_retention_days'),        30) AS UNSIGNED) AS retention_days,
    CAST(COALESCE(JSON_VALUE(m, '$.version_apply_immediately'),      0) AS UNSIGNED) AS apply_immediately,
    CAST(COALESCE(JSON_VALUE(m, '$.version_allow_members_view'),     0) AS UNSIGNED) AS allow_members_view,
    CAST(COALESCE(JSON_VALUE(m, '$.version_allow_editors_restore'),  0) AS UNSIGNED) AS allow_editors_restore,
    CAST(COALESCE(JSON_VALUE(m, '$.version_history_bytes'),          0) AS UNSIGNED) AS version_history_bytes
  FROM (
    SELECT IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata) AS m
    FROM organisation
    WHERE domain_id = _domain_id
    LIMIT 1
  ) t;
END$

DELIMITER ;
