-- File: fix_existing_users_mfs_ack.sql

DELIMITER $

DROP PROCEDURE IF EXISTS `fix_existing_users_mfs_ack`$

CREATE PROCEDURE `fix_existing_users_mfs_ack`()
BEGIN
  DECLARE _finished INT DEFAULT 0;
  DECLARE _user_id VARCHAR(16);
  DECLARE _user_db VARCHAR(255);
  DECLARE _max_id INT(11) UNSIGNED;
  
  DECLARE user_cursor CURSOR FOR 
    SELECT id, db_name
    FROM yp.entity
    WHERE type = 'drumate'
      AND status = 'active';
  
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
  
  SELECT IFNULL(MAX(id), 0) INTO _max_id
  FROM yp.mfs_changelog;
  
  OPEN user_cursor;
  
  user_loop: LOOP
    FETCH user_cursor INTO _user_id, _user_db;
    
    IF _finished = 1 THEN
      LEAVE user_loop;
    END IF;
    
    -- Initialize mfs_ack for this user
    SET @sql = CONCAT(
      'INSERT IGNORE INTO ', _user_db, '.mfs_ack ',
      '(user_id, last_read_id, mtime) ',
      'VALUES (''', _user_id, ''', ', _max_id, ', UNIX_TIMESTAMP())'
    );
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
  END LOOP user_loop;
  
  CLOSE user_cursor;
  
  SELECT 'Migration completed' AS status;
  
END$

DELIMITER ;