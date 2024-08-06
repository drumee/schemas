DELIMITER $
DROP PROCEDURE IF EXISTS `update_device_push_token`$
CREATE PROCEDURE `update_device_push_token`(
  IN _device_id VARCHAR(200),
  IN _push_token text
)
BEGIN
  UPDATE device_registation SET push_token=_push_token
  WHERE device_id = _device_id;
  SELECT * FROM device_registation WHERE device_id=_device_id;
END$

DELIMITER ;