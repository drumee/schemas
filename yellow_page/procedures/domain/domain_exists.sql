DELIMITER $


DROP PROCEDURE IF EXISTS `domain_exists`$
CREATE PROCEDURE `domain_exists`(
  IN _key VARCHAR(1000)
)
BEGIN
  SELECT * FROM domain WHERE `name` = _key  OR id = _key ; 
END $


DELIMITER ;