DELIMITER $

DROP PROCEDURE IF EXISTS `authn_store`$
CREATE PROCEDURE `authn_store`(
  IN _token VARCHAR(90)  CHARACTER SET ascii,
  IN _value JSON
)
BEGIN
  INSERT IGNORE INTO authn (`token`, `value`) VALUES(_token, _value);
END$

DELIMITER ;