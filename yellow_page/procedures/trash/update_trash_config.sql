-- Purpose: Update system-wide trash expiry configuration

DROP PROCEDURE IF EXISTS `update_trash_config`;

DELIMITER $

CREATE PROCEDURE `update_trash_config`(
  IN _expiry_days INT,
  IN _auto_delete_enabled TINYINT
)
BEGIN
  DECLARE _error_msg VARCHAR(255);
  
  -- Validate expiry_days (1-365 days)
  IF _expiry_days < 1 OR _expiry_days > 365 THEN
    SET _error_msg = 'Invalid expiry_days: Must be between 1 and 365';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = _error_msg;
  END IF;
  
  -- Validate auto_delete_enabled (0 or 1)
  IF _auto_delete_enabled NOT IN (0, 1) THEN
    SET _error_msg = 'Invalid auto_delete_enabled: Must be 0 (disabled) or 1 (enabled)';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = _error_msg;
  END IF;
  
  -- Update config
  UPDATE trash_expiry_config
  SET 
    expiry_days = _expiry_days,
    auto_delete_enabled = _auto_delete_enabled,
    mtime = UNIX_TIMESTAMP()
  WHERE id = 1;
  
  SELECT 
    expiry_days,
    auto_delete_enabled,
    last_run_time,
    FROM_UNIXTIME(last_run_time) as last_run_date,
    FROM_UNIXTIME(ctime) as created_at,
    FROM_UNIXTIME(mtime) as updated_at,
    'Configuration updated successfully' as message
  FROM trash_expiry_config
  WHERE id = 1;
END$

DELIMITER ;