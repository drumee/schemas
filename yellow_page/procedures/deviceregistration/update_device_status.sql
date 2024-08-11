DELIMITER $
-- =========================================================
-- update status
-- =========================================================

DROP PROCEDURE IF EXISTS `update_device_status`$
CREATE PROCEDURE `update_device_status`(
  IN _device_id VARCHAR(200),
  IN _status varchar(20)
)
BEGIN
  UPDATE device_registation SET status=_status
  WHERE device_id = _device_id;
  SELECT * FROM device_registation WHERE device_id=_device_id;
END$

DELIMITER ;