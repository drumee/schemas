DELIMITER $



DROP PROCEDURE IF EXISTS `role_rename`$
CREATE PROCEDURE `role_rename`(
    IN _role_id INT(10) ,
    _org_id VARCHAR(50),
    _name VARCHAR(255)   
)
BEGIN
    
  SELECT unique_role(_name,NULL,_org_id) INTO _name;
  UPDATE role SET name = _name WHERE id = _role_id;
  SELECT * FROM role WHERE id = _role_id  ; 

END$



DELIMITER ;