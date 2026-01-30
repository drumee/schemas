-- Purpose: Get expired trash items for the current hub

DROP PROCEDURE IF EXISTS `mfs_get_expired_trash`;

DELIMITER $

CREATE PROCEDURE `mfs_get_expired_trash`()
BEGIN
  DECLARE _expiry_days INT;
  DECLARE _auto_delete_enabled TINYINT;
  DECLARE _expiry_timestamp INT;
  
  -- Get config
  SELECT expiry_days, auto_delete_enabled 
  INTO _expiry_days, _auto_delete_enabled
  FROM yp.trash_expiry_config 
  WHERE id = 1;
  
  -- If auto-delete is disabled, return empty result
  IF _auto_delete_enabled = 0 THEN
    SELECT NULL as id LIMIT 0;
  ELSE
    -- Calculate expiry timestamp
    SET _expiry_timestamp = UNIX_TIMESTAMP() - (_expiry_days * 86400);
    
    -- Return expired items
    SELECT 
      id,
      user_filename,
      extension,
      category,
      filesize,
      owner_id,
      trashed_time,
      FROM_UNIXTIME(trashed_time) as trashed_date,
      FLOOR((UNIX_TIMESTAMP() - trashed_time) / 86400) as days_in_trash
    FROM trash_media
    WHERE status = 'deleted'
      AND trashed_time > 0
      AND trashed_time < _expiry_timestamp
    ORDER BY trashed_time ASC;
  END IF;
END$

DELIMITER ;