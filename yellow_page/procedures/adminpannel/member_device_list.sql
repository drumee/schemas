DELIMITER $

DROP PROCEDURE IF EXISTS `member_device_list`$
CREATE PROCEDURE `member_device_list`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT
    sys_id,
    name,
    platform,
    version,
    status,
    ctime,
    mtime
  FROM device
  WHERE uid = _uid AND status = 'active'
  ORDER BY mtime DESC;
END $

DELIMITER ;