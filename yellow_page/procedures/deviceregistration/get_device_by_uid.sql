DELIMITER $
DROP PROCEDURE IF EXISTS `get_device_by_uid`$
CREATE PROCEDURE `get_device_by_uid`(
  IN _uid varchar(16)
)
BEGIN
  SELECT _uid  id ,  push_token FROM device_registation WHERE uid = _uid;
END$
DELIMITER ;