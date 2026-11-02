DELIMITER $

-- =========================================================
-- organisation_set_access_rules
-- =========================================================
-- Store the org's access rules (a JSON array, validated in admin-api) at
-- organisation.metadata.$.access_rules. JSON_SET keeps every other key
-- (retention policy, ident, ...); a NULL / invalid legacy metadata starts
-- from '{}', as organisation_set_retention does. Anything but a JSON array
-- is refused with an error row rather than stored.
DROP PROCEDURE IF EXISTS `organisation_set_access_rules`$
CREATE PROCEDURE `organisation_set_access_rules`(
  IN _domain_id INT,
  IN _rules     LONGTEXT
)
proc: BEGIN
  IF _rules IS NULL OR JSON_VALID(_rules) = 0 OR JSON_TYPE(_rules) != 'ARRAY' THEN
    SELECT 'INVALID_RULES' AS error;
    LEAVE proc;
  END IF;

  UPDATE organisation
     SET metadata = JSON_SET(
       IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
       '$.access_rules', JSON_EXTRACT(_rules, '$')
     )
   WHERE domain_id = _domain_id;

  SELECT ROW_COUNT() AS updated;
END$

DELIMITER ;
