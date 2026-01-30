-- Purpose: Get all trash items for a hub (for manual empty or auto-delete)

DROP PROCEDURE IF EXISTS `empty_trash_for_hub`;

DELIMITER $

CREATE PROCEDURE `empty_trash_for_hub`(
  IN _hub_id VARCHAR(16)
)
empty_trash_for_hub:BEGIN
  DECLARE _db_name VARCHAR(64);
  DECLARE _table_exists INT;
  DECLARE _column_exists INT;
  
  SELECT db_name INTO _db_name
  FROM yp.entity
  WHERE id = _hub_id
    AND area = 'hub'
    AND status = 'active'
  LIMIT 1;
  
  -- Validate hub exists
  IF _db_name IS NULL OR _db_name = '' THEN
    SELECT 
      NULL as nid,
      'ERROR: Hub not found or not active' as error_message;
    LEAVE empty_trash_for_hub;
  END IF;
  
  -- Check if trash_media table exists
  SET @st = CONCAT(
    'SELECT COUNT(*) INTO @table_exists ',
    'FROM information_schema.TABLES ',
    'WHERE TABLE_SCHEMA = ''', _db_name, ''' ',
    'AND TABLE_NAME = ''trash_media'''
  );
  PREPARE stmt FROM @st;
  EXECUTE stmt;
  SET _table_exists = @table_exists;
  DEALLOCATE PREPARE stmt;
  
  IF _table_exists = 0 THEN
    SELECT 
      NULL as nid,
      'ERROR: trash_media table does not exist in this hub' as error_message;
    LEAVE empty_trash_for_hub;
  END IF;
  
  -- Check if trashed_time column exists
  SET @st = CONCAT(
    'SELECT COUNT(*) INTO @column_exists ',
    'FROM information_schema.COLUMNS ',
    'WHERE TABLE_SCHEMA = ''', _db_name, ''' ',
    'AND TABLE_NAME = ''trash_media'' ',
    'AND COLUMN_NAME = ''trashed_time'''
  );
  PREPARE stmt FROM @st;
  EXECUTE stmt;
  SET _column_exists = @column_exists;
  DEALLOCATE PREPARE stmt;
  
  -- Return all trash items for this hub
  SET @st = CONCAT(
    'SELECT ',
    'id as nid, ',
    'user_filename, ',
    'file_path, ',
    'filesize, ',
    IF(_column_exists > 0, 
      'trashed_time, FROM_UNIXTIME(trashed_time) as trashed_date, FLOOR((UNIX_TIMESTAMP() - trashed_time) / 86400) as days_in_trash',
      '0 as trashed_time, NULL as trashed_date, NULL as days_in_trash'
    ), ' ',
    'FROM `', _db_name, '`.trash_media ',
    'ORDER BY ', 
    IF(_column_exists > 0, 'trashed_time ASC', 'upload_time ASC')
  );
  
  PREPARE stmt FROM @st;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END$

DELIMITER ;