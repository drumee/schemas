DELIMITER $

-- =========================================================
-- organisation_get_access_rules
-- =========================================================
-- Org Structure "Access rules" (stored, not enforced). Lives in
-- organisation.metadata.$.access_rules next to the retention policy keys.
-- NULL = never saved (or unreadable metadata): the service shows defaults.
DROP PROCEDURE IF EXISTS `organisation_get_access_rules`$
CREATE PROCEDURE `organisation_get_access_rules`(
  IN _domain_id INT
)
BEGIN
  SELECT
    IF(metadata IS NOT NULL AND JSON_VALID(metadata),
       JSON_EXTRACT(metadata, '$.access_rules'),
       NULL) AS access_rules
  FROM organisation
  WHERE domain_id = _domain_id;
END$

DELIMITER ;
