DELIMITER $

DROP PROCEDURE IF EXISTS `organisation_list_retention`$
CREATE PROCEDURE `organisation_list_retention`()
BEGIN
  -- Orgs that EXPLICITLY configured a versioning retention policy. Used by
  -- versionRetentionWorker to enforce the window only where an admin opted in
  -- (orgs without the key keep all versions — no surprise auto-purge).
  SELECT
    id AS org_id,
    domain_id,
    CAST(JSON_VALUE(metadata, '$.version_retention_days') AS UNSIGNED) AS retention_days
  FROM organisation
  WHERE metadata IS NOT NULL
    AND metadata <> ''
    AND JSON_VALID(metadata)
    AND JSON_VALUE(metadata, '$.version_retention_days') IS NOT NULL
    AND domain_id IS NOT NULL;
END$

DELIMITER ;
