DELIMITER $


DROP PROCEDURE IF EXISTS `role_delete`$
CREATE PROCEDURE `role_delete`(
  IN _role_id INT(10) ,
  IN _org_id VARCHAR(16)
)
BEGIN

  DELETE FROM map_role WHERE role_id = _role_id AND  org_id = _org_id;
  DELETE FROM role WHERE id = _role_id AND  org_id = _org_id; 
  SELECT _role_id role_id, _org_id org_id;

END $


DELIMITER ;