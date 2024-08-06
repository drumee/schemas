DELIMITER $
DROP PROCEDURE IF EXISTS `device_registration`$
CREATE PROCEDURE `device_registration`(
  IN _device_id VARCHAR(200),
  IN _device_type enum('ios','android','web'),
  IN _push_token text,
  IN _uid varchar(16),
  IN _status varchar(20)
)
BEGIN
  IF EXISTS(SELECT device_id FROM device_registation WHERE device_id = _device_id) THEN
      UPDATE device_registation SET push_token = _push_token, uid = _uid, status = _status, mtime = UNIX_TIMESTAMP() WHERE device_id = _device_id;
  ELSE
      INSERT INTO device_registation (`device_id`, `device_type`, `push_token`, `uid`, `status`, `ctime`, `mtime`) 
      VALUES (_device_id, _device_type, _push_token, _uid, _status, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
  END IF; 
END$

DELIMITER ;