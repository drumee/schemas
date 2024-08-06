DELIMITER $



DROP PROCEDURE IF EXISTS `domain_exists`$
CREATE PROCEDURE `domain_exists`(
  IN _key VARCHAR(1000)
)
BEGIN
   DECLARE _domain_id INT(10); 
   SELECT * FROM domain WHERE name = _key  or id = _key ; 
END $


DELIMITER ;