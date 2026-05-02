DELIMITER $
DROP PROCEDURE IF EXISTS `label_list`$
CREATE PROCEDURE `label_list`()
BEGIN
  SELECT id, name, color, created_by, ctime, mtime
  FROM label
  ORDER BY name ASC;
END$
DELIMITER ;
