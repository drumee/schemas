DELIMITER $

DROP PROCEDURE IF EXISTS `custom_table_register`$
CREATE PROCEDURE `custom_table_register`(
  IN _name VARCHAR(80),
  IN _uid VARCHAR(16)
)
BEGIN
  INSERT INTO custom VALUES(null, yp.uniqueId(), _name, _uid, UNIX_TIMESTAMP());
  SELECT *, id AS table_name FROM custom WHERE `name` = _name;
END$

DELIMITER ;
