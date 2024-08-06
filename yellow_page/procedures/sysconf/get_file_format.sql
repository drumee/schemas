DELIMITER $


DROP PROCEDURE IF EXISTS `get_file_format`$
CREATE PROCEDURE `get_file_format`(
)
BEGIN
  SELECT 
  extension AS `key`, 
  extension, category, 
  mimetype, capability FROM filecap;
END $

DELIMITER ;
