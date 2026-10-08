DELIMITER $

-- =========================================================
-- org_setup_state
-- =========================================================
-- Whether an organisation has been through the "Set up your organization"
-- wizard (B2B Org Structure, Figma 900:149766), and how many departments it
-- has — the two things the desk weighs before offering the wizard to the
-- owner. The flag lives in organisation.metadata ($.org_setup_done, a unix
-- time) beside $.access_rules: no new column for one boolean.
--
-- A malformed metadata value reads as "not set up" rather than failing.
DROP PROCEDURE IF EXISTS `org_setup_state`$
CREATE PROCEDURE `org_setup_state`(
  IN _domain_id INT UNSIGNED
)
BEGIN
  SELECT
    IF(o.metadata IS NOT NULL AND JSON_VALID(o.metadata),
       IFNULL(JSON_VALUE(o.metadata, '$.org_setup_done'), 0),
       0) AS setup_done,
    (SELECT COUNT(*) FROM department d WHERE d.domain_id = _domain_id) AS department_count
  FROM organisation o
  WHERE o.domain_id = _domain_id;
END$

DELIMITER ;
