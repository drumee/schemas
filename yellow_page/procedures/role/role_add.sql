DELIMITER $

DROP PROCEDURE IF EXISTS `role_add`$
CREATE PROCEDURE `role_add`(
  IN _name VARCHAR(500),
  IN _org_id VARCHAR(16)
)
BEGIN
  DECLARE _position int(11) unsigned;
  SELECT MAX(position) FROM role WHERE org_id =_org_id INTO _position;
  SELECT IFNULL(_position,0) +1 INTO _position;

  SELECT unique_role(_name,NULL,_org_id) INTO _name;
  INSERT INTO role (name,org_id, position)  SELECT _name, _org_id,_position;
  
  SELECT id role_id, name,org_id,position FROM role WHERE name = _name AND  org_id = _org_id  ; 

END $

DELIMITER ;