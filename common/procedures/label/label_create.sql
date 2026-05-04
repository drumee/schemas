DELIMITER $
DROP PROCEDURE IF EXISTS `label_create`$
CREATE PROCEDURE `label_create`(
  IN _id VARCHAR(16),
  IN _name VARCHAR(120),
  IN _color VARCHAR(9),
  IN _created_by VARCHAR(16)
)
BEGIN
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  INSERT INTO label (id, name, color, created_by, ctime, mtime)
  VALUES (_id, _name, IFNULL(_color, '#AEAEB2'), _created_by, _now, _now);

  SELECT id, name, color, created_by, ctime, mtime
  FROM label
  WHERE id = _id;
END$
DELIMITER ;
