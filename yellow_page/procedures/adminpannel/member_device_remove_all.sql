DELIMITER $

DROP PROCEDURE IF EXISTS `member_device_remove_all`$
CREATE PROCEDURE `member_device_remove_all`(
  IN _uid VARCHAR(16)
)
BEGIN
  UPDATE device
  SET status = 'revoked', mtime = UNIX_TIMESTAMP()
  WHERE uid = _uid AND status = 'active';

  SELECT ROW_COUNT() AS affected;
END $

DELIMITER ;