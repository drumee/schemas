DELIMITER $
DROP PROCEDURE IF EXISTS `unregister_user_with_device`$
CREATE PROCEDURE `unregister_user_with_device`(
  IN _device_id VARCHAR(200)
)
BEGIN
  UPDATE device_registation SET uid=NULL 
  WHERE device_id = _device_id;
END$

DELIMITER ;