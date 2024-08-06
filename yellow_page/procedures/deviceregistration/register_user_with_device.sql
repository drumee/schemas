DELIMITER $
DROP PROCEDURE IF EXISTS `user_register_with_device`$
CREATE PROCEDURE `user_register_with_device`(
  IN _device_id VARCHAR(200),
  IN _uid varchar(16)
)
BEGIN
  UPDATE device_registation SET uid=_uid 
  WHERE device_id = _device_id;
  SELECT * FROM device_registation WHERE device_id=_device_id;
END$

DELIMITER ;