DELIMITER $

DROP PROCEDURE IF EXISTS `member_device_remove`$
CREATE PROCEDURE `member_device_remove`(
  IN _sys_id INT UNSIGNED,
  IN _uid VARCHAR(16)
)
BEGIN
  UPDATE device
  SET status = 'revoked', mtime = UNIX_TIMESTAMP()
  WHERE sys_id = _sys_id AND uid = _uid;

  SELECT ROW_COUNT() AS affected;
END $

DELIMITER ;