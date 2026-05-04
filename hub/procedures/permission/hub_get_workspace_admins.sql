DELIMITER $

DROP PROCEDURE IF EXISTS `hub_get_workspace_admins`$
CREATE PROCEDURE `hub_get_workspace_admins`()
BEGIN
  SELECT DISTINCT entity_id
  FROM permission
  WHERE resource_id = '*'
    AND permission = 31
    AND (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP());
END $

DELIMITER ;