DELIMITER $

-- =========================================================
-- org_reporting_list
-- =========================================================
-- The organisation's reporting lines {uid, manager_uid}.
DROP PROCEDURE IF EXISTS `org_reporting_list`$
CREATE PROCEDURE `org_reporting_list`(IN _domain_id INT UNSIGNED)
BEGIN
  SELECT uid, manager_uid FROM org_reporting WHERE domain_id = _domain_id;
END$

DELIMITER ;
