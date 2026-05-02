DELIMITER $
DROP PROCEDURE IF EXISTS `label_update`$
CREATE PROCEDURE `label_update`(
  IN _id VARCHAR(16),
  IN _name VARCHAR(120),
  IN _color VARCHAR(9)
)
BEGIN
  UPDATE label
     SET name  = IFNULL(_name, name),
         color = IFNULL(_color, color),
         mtime = UNIX_TIMESTAMP()
   WHERE id = _id;

  SELECT id, name, color, created_by, ctime, mtime
  FROM label
  WHERE id = _id;
END$
DELIMITER ;
