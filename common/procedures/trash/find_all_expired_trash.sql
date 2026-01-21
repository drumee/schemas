-- Purpose: Find expired trash items across all active hubs

DROP PROCEDURE IF EXISTS `find_all_expired_trash`;

DELIMITER $

CREATE PROCEDURE `find_all_expired_trash`(
  IN _expiry_days INT
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db_name VARCHAR(64);
  DECLARE _cutoff_time INT;
  DECLARE _expired_count INT;
  
  DECLARE hub_cursor CURSOR FOR 
    SELECT id, db_name 
    FROM yp.entity 
    WHERE db_name IS NOT NULL 
      AND db_name != '' 
      AND area = 'hub'
      AND status = 'active'
    ORDER BY db_name;
    
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;
  
  -- Calculate cutoff time (current time - expiry days)
  SET _cutoff_time = UNIX_TIMESTAMP() - (_expiry_days * 24 * 60 * 60);
  
  -- Temporary table to store results
  DROP TEMPORARY TABLE IF EXISTS tmp_expired_trash;
  CREATE TEMPORARY TABLE tmp_expired_trash (
    hub_id VARCHAR(16),
    db_name VARCHAR(64),
    nid CHAR(16),
    user_filename VARCHAR(512),
    file_path VARCHAR(1024),
    filesize BIGINT,
    trashed_time INT,
    days_in_trash INT,
    PRIMARY KEY (hub_id, nid)
  ) ENGINE=MEMORY;
  
  SELECT CONCAT(
    '========================================\n',
    'Scanning for expired trash items\n',
    'Cutoff date: ', FROM_UNIXTIME(_cutoff_time), '\n',
    'Expiry days: ', _expiry_days, '\n',
    '========================================'
  ) as info;
  
  OPEN hub_cursor;
  
  read_loop: LOOP
    FETCH hub_cursor INTO _hub_id, _db_name;
    
    IF _done THEN
      LEAVE read_loop;
    END IF;
    
    -- Check if trash_media table exists
    SET @table_exists = 0;
    SET @st = CONCAT(
      'SELECT COUNT(*) INTO @table_exists ',
      'FROM information_schema.TABLES ',
      'WHERE TABLE_SCHEMA = ''', _db_name, ''' ',
      'AND TABLE_NAME = ''trash_media'''
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    IF @table_exists = 0 THEN
      SELECT CONCAT('⊘ SKIP: ', _db_name, ' (no trash_media table)') as status;
      ITERATE read_loop;
    END IF;
    
    -- Check if trashed_time column exists
    SET @column_exists = 0;
    SET @st = CONCAT(
      'SELECT COUNT(*) INTO @column_exists ',
      'FROM information_schema.COLUMNS ',
      'WHERE TABLE_SCHEMA = ''', _db_name, ''' ',
      'AND TABLE_NAME = ''trash_media'' ',
      'AND COLUMN_NAME = ''trashed_time'''
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    IF @column_exists = 0 THEN
      SELECT CONCAT('⊘ SKIP: ', _db_name, ' (no trashed_time column - migration needed)') as status;
      ITERATE read_loop;
    END IF;
    
    -- Find expired items in this hub
    SET @st = CONCAT(
      'INSERT INTO tmp_expired_trash ',
      'SELECT ',
      '''', _hub_id, ''', ',
      '''', _db_name, ''', ',
      'id, ',
      'user_filename, ',
      'file_path, ',
      'filesize, ',
      'trashed_time, ',
      'FLOOR((UNIX_TIMESTAMP() - trashed_time) / 86400) as days_in_trash ',
      'FROM `', _db_name, '`.trash_media ',
      'WHERE trashed_time > 0 ',
      'AND trashed_time < ', _cutoff_time
    );
    
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    SET _expired_count = ROW_COUNT();
    DEALLOCATE PREPARE stmt;
    
    IF _expired_count > 0 THEN
      SELECT CONCAT('✓ Found ', _expired_count, ' expired items in: ', _db_name) as status;
    ELSE
      SELECT CONCAT('○ No expired items in: ', _db_name) as status;
    END IF;
    
  END LOOP;
  
  CLOSE hub_cursor;
  
  SELECT '========================================' as '';
  SELECT 'EXPIRED TRASH SUMMARY' as '';
  SELECT '========================================' as '';
  
  SELECT 
    hub_id,
    db_name,
    COUNT(*) as expired_count,
    SUM(filesize) as total_size_bytes,
    ROUND(SUM(filesize) / 1024 / 1024, 2) as total_size_mb
  FROM tmp_expired_trash
  GROUP BY hub_id, db_name
  ORDER BY expired_count DESC;
  
  SELECT '========================================' as '';
  SELECT 'TOTAL ACROSS ALL HUBS' as '';
  SELECT '========================================' as '';
  
  SELECT 
    COUNT(*) as total_expired_items,
    COUNT(DISTINCT hub_id) as affected_hubs,
    SUM(filesize) as total_size_bytes,
    ROUND(SUM(filesize) / 1024 / 1024, 2) as total_size_mb,
    ROUND(SUM(filesize) / 1024 / 1024 / 1024, 2) as total_size_gb
  FROM tmp_expired_trash;
  
  -- Return detailed items (limited to 100 for performance)
  SELECT '========================================' as '';
  SELECT 'SAMPLE EXPIRED ITEMS (Max 100)' as '';
  SELECT '========================================' as '';
  
  SELECT 
    hub_id,
    db_name,
    nid,
    user_filename,
    ROUND(filesize / 1024 / 1024, 2) as size_mb,
    FROM_UNIXTIME(trashed_time) as trashed_date,
    days_in_trash
  FROM tmp_expired_trash
  ORDER BY trashed_time ASC
  LIMIT 100;
  
  -- Cleanup
  DROP TEMPORARY TABLE IF EXISTS tmp_expired_trash;
END$

DELIMITER ;