DELIMITER $
DROP PROCEDURE IF EXISTS `custom_table_get`$
CREATE PROCEDURE `custom_table_get`(
  IN _name VARCHAR(80)
)
BEGIN
  SELECT *, id AS table_name FROM custom WHERE `name` = _name OR id=_name;
END$
DELIMITER ;
