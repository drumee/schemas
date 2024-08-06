DELIMITER $


DROP PROCEDURE IF EXISTS `domain_create`$
CREATE PROCEDURE `domain_create`(
  IN _name VARCHAR(1000)
)
BEGIN
  DECLARE _domain_id INT(10); 
  SELECT CONCAT(_name,".", main_domain()) INTO _name;
  INSERT INTO domain (name) SELECT _name ; 
  SELECT id FROM domain WHERE name = _name INTO _domain_id;
  SELECT  * FROM domain WHERE id = _domain_id;
END $


DELIMITER ;