
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_set_devices`$
CREATE PROCEDURE `licence_set_devices`(
  IN  _key varchar(128),
  IN _devices JSON
)
BEGIN
  UPDATE licence SET  devices=_devices WHERE `key` = _key;
END$

DELIMITER ;
