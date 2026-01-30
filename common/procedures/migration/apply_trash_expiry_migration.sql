-- Migration: Add trashed_time column to trash_media
-- Purpose: Track when items were moved to trash

-- This migration applies to all hub databases automatically
-- Uses yp.migration_log to prevent duplicate execution

DELIMITER $

DROP PROCEDURE IF EXISTS `apply_trash_expiry_migration`$

CREATE PROCEDURE `apply_trash_expiry_migration`()
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db_name VARCHAR(64);
  DECLARE _error_msg TEXT;
  DECLARE _column_exists INT;
  
  DECLARE hub_cursor CURSOR FOR 
    SELECT id, db_name 
    FROM yp.entity 
    WHERE db_name IS NOT NULL 
      AND db_name != '' 
      AND area = 'hub'
      AND status = 'active'
    ORDER BY db_name;
    
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
  BEGIN
    GET DIAGNOSTICS CONDITION 1 _error_msg = MESSAGE_TEXT;
  END;
  
  SELECT CONCAT(
    '========================================',
    '\nStarting trash_media migration',
    '\nTimestamp: ', FROM_UNIXTIME(UNIX_TIMESTAMP()),
    '\n========================================'
  ) as info;
  
  OPEN hub_cursor;
  
  read_loop: LOOP
    FETCH hub_cursor INTO _hub_id, _db_name;
    
    IF _done THEN
      LEAVE read_loop;
    END IF;
    
    SET _error_msg = NULL;
    
    -- Check if already migrated
    SET @already_migrated = 0;
    SELECT COUNT(*) INTO @already_migrated
    FROM yp.migration_log
    WHERE hub_id = _hub_id 
      AND migration_name = 'add_trashed_time_to_trash_media'
      AND status = 'success';
    
    IF @already_migrated > 0 THEN
      SELECT CONCAT('⊘ SKIP: ', _db_name, ' (already migrated)') as status;
      ITERATE read_loop;
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
      INSERT INTO yp.migration_log 
      (hub_id, db_name, migration_name, status, error_msg, executed_at) 
      VALUES (
        _hub_id, 
        _db_name, 
        'add_trashed_time_to_trash_media', 
        'skipped', 
        'Table trash_media does not exist', 
        UNIX_TIMESTAMP()
      );
      SELECT CONCAT('⊘ SKIP: ', _db_name, ' (no trash_media table)') as status;
      ITERATE read_loop;
    END IF;
    
    -- Check if column already exists
    SET _column_exists = 0;
    SET @st = CONCAT(
      'SELECT COUNT(*) INTO @col_exists ',
      'FROM information_schema.COLUMNS ',
      'WHERE TABLE_SCHEMA = ''', _db_name, ''' ',
      'AND TABLE_NAME = ''trash_media'' ',
      'AND COLUMN_NAME = ''trashed_time'''
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    SET _column_exists = @col_exists;
    DEALLOCATE PREPARE stmt;
    
    IF _column_exists > 0 THEN
      INSERT INTO yp.migration_log 
      (hub_id, db_name, migration_name, status, error_msg, executed_at) 
      VALUES (
        _hub_id, 
        _db_name, 
        'add_trashed_time_to_trash_media', 
        'skipped', 
        'Column trashed_time already exists', 
        UNIX_TIMESTAMP()
      );
      SELECT CONCAT('⊘ SKIP: ', _db_name, ' (column exists)') as status;
      ITERATE read_loop;
    END IF;
    
    -- Perform migration
    BEGIN
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
      BEGIN
        GET DIAGNOSTICS CONDITION 1 _error_msg = MESSAGE_TEXT;
        
        INSERT INTO yp.migration_log 
        (hub_id, db_name, migration_name, status, error_msg, executed_at) 
        VALUES (
          _hub_id, 
          _db_name, 
          'add_trashed_time_to_trash_media', 
          'failed', 
          _error_msg, 
          UNIX_TIMESTAMP()
        );
        
        SELECT CONCAT('✗ FAILED: ', _db_name, ' - ', _error_msg) as status;
      END;
      
      SELECT CONCAT('► Processing: ', _db_name, '...') as status;
      
      -- Add column
      SET @st = CONCAT(
        'ALTER TABLE `', _db_name, '`.`trash_media` ',
        'ADD COLUMN `trashed_time` INT(11) UNSIGNED NOT NULL DEFAULT 0 ',
        'COMMENT ''UNIX timestamp when item was trashed'' ',
        'AFTER `upload_time`'
      );
      PREPARE stmt FROM @st;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
      -- Add index
      SET @st = CONCAT(
        'ALTER TABLE `', _db_name, '`.`trash_media` ',
        'ADD INDEX `idx_trashed_time` (`trashed_time`)'
      );
      PREPARE stmt FROM @st;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
      -- Update existing rows with current timestamp
      -- (All existing trash items get current time as their trashed_time)
      SET @st = CONCAT(
        'UPDATE `', _db_name, '`.`trash_media` ',
        'SET trashed_time = UNIX_TIMESTAMP() ',
        'WHERE trashed_time = 0'
      );
      PREPARE stmt FROM @st;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
      -- Log success
      INSERT INTO yp.migration_log 
      (hub_id, db_name, migration_name, status, error_msg, executed_at) 
      VALUES (
        _hub_id, 
        _db_name, 
        'add_trashed_time_to_trash_media', 
        'success', 
        NULL, 
        UNIX_TIMESTAMP()
      );
      
      SELECT CONCAT('✓ SUCCESS: ', _db_name) as status;
    END;
    
  END LOOP;
  
  CLOSE hub_cursor;
  
  SELECT '========================================' as '';
  SELECT 'MIGRATION SUMMARY' as '';
  SELECT '========================================' as '';
  
  SELECT 
    status,
    COUNT(*) as count,
    GROUP_CONCAT(db_name SEPARATOR ', ') as database_list
  FROM yp.migration_log
  WHERE migration_name = 'add_trashed_time_to_trash_media'
  GROUP BY status;
  
  SELECT '========================================' as '';
  SELECT CONCAT('Completed at: ', FROM_UNIXTIME(UNIX_TIMESTAMP())) as info;
  SELECT '========================================' as '';
END$

DELIMITER ;
CALL apply_trash_expiry_migration();
DROP PROCEDURE IF EXISTS `apply_trash_expiry_migration`;

-- 1. First, ensure yp.migration_log table exists:

-- 2. Apply the migration procedure:

-- 3. Execute the migration:
--    CALL apply_trash_expiry_migration();

-- 4. Verify results:
--    SELECT * FROM yp.migration_log 
--    WHERE migration_name = 'add_trashed_time_to_trash_media'
--    ORDER BY executed_at DESC;