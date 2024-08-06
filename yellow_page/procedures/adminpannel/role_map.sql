DELIMITER $
DROP PROCEDURE IF EXISTS `role_map`$
CREATE PROCEDURE `role_map`(
  IN _uid VARCHAR(16), 
  IN _roles  MEDIUMTEXT,
  IN _org_id VARCHAR(16)
)
BEGIN
 DECLARE _idx INTEGER DEFAULT 0;
 DECLARE _id VARCHAR(16);
 DECLARE _length INTEGER DEFAULT 0;
 
 SELECT  JSON_LENGTH(_roles)  INTO _length;

 DELETE FROM map_role WHERE uid=_uid AND org_id =_org_id ;

 WHILE _idx < _length  DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_roles, CONCAT("$[", _idx, "]"))) INTO _id;
    INSERT INTO map_role(uid,role_id, org_id) 
    SELECT _uid,_id,_org_id ON DUPLICATE KEY UPDATE uid =_uid;
    SELECT _idx + 1 INTO _idx;
  END WHILE;
END$
DELIMITER ;