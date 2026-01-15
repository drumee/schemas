-- Purpose: Get system-wide trash expiry configuration

DROP PROCEDURE IF EXISTS `get_trash_config`;

DELIMITER $

CREATE PROCEDURE `get_trash_config`()
BEGIN
  SELECT 
    expiry_days,
    auto_delete_enabled,
    last_run_time,
    FROM_UNIXTIME(last_run_time) as last_run_date,
    FROM_UNIXTIME(ctime) as created_at,
    FROM_UNIXTIME(mtime) as updated_at
  FROM trash_expiry_config
  WHERE id = 1;
END$

DELIMITER ;