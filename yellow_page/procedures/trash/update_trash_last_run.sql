-- Purpose: Update last run time for auto-delete worker

DROP PROCEDURE IF EXISTS `update_trash_last_run`;

DELIMITER $

CREATE PROCEDURE `update_trash_last_run`()
BEGIN
  -- Update last run time to current timestamp
  UPDATE trash_expiry_config
  SET 
    last_run_time = UNIX_TIMESTAMP(),
    mtime = UNIX_TIMESTAMP()
  WHERE id = 1;
  
  -- Return updated timestamp
  SELECT 
    last_run_time,
    FROM_UNIXTIME(last_run_time) as last_run_date,
    'Last run time updated successfully' as message
  FROM trash_expiry_config 
  WHERE id = 1;
END$

DELIMITER ;