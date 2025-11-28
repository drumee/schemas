-- File: schemas/drumate/procedures/mfs_mark_all_read.sql
-- Purpose: Mark all notifications as read by updating last_read_id

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_mark_all_read`$

CREATE PROCEDURE `mfs_mark_all_read`(
  IN _user_id VARCHAR(16),
  IN _last_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _mtime INT(11) UNSIGNED;
  
  SELECT UNIX_TIMESTAMP() INTO _mtime;
  
  INSERT INTO mfs_ack (user_id, last_read_id, mtime)
  VALUES (_user_id, _last_id, _mtime)
  ON DUPLICATE KEY UPDATE
    last_read_id = _last_id,
    mtime = _mtime;
  
  SELECT 
    user_id,
    last_read_id,
    mtime,
    'ok' AS status
  FROM mfs_ack
  WHERE user_id = _user_id;
  
END$

DELIMITER ;