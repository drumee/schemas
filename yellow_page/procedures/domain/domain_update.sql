DELIMITER $



DROP PROCEDURE IF EXISTS `domain_update`$
CREATE PROCEDURE `domain_update`(
  IN _name VARCHAR(1000),
  IN _domain_id INT(10)
)
BEGIN
  SELECT CONCAT(_name,".", main_domain()) INTO _name;
  UPDATE domain SET name= _name WHERE id = _domain_id;
  SELECT  * FROM domain WHERE id = _domain_id;
END $


DELIMITER ;