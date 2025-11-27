-- File: schemas/drumate/procedures/mfs_get_unread_count.sql
-- Purpose: Get count of unread notifications for current user

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_unread_count`$

CREATE PROCEDURE `mfs_get_unread_count`(
  IN _user_id VARCHAR(16)
)
BEGIN
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;
  
  SELECT IFNULL(last_read_id, 0) INTO _last_read_id
  FROM mfs_ack
  WHERE user_id = _user_id;
  
  -- Count unread notifications from yp.mfs_changelog
  SELECT COUNT(*) AS unread_count
  FROM yp.mfs_changelog
  WHERE id > _last_read_id
    AND uid != _user_id;  -- Exclude own actions
  
END$

DELIMITER ;