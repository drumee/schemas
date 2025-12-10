-- File: schemas/drumate/procedures/desk/desk_disk_usage.sql
-- Purpose: Get disk usage for user (owned files + owned hubs)
-- Excludes: Files in hubs where user is member but NOT owner

DELIMITER $

DROP PROCEDURE IF EXISTS `desk_disk_usage`$

CREATE PROCEDURE `desk_disk_usage`(
  IN _uid VARCHAR(16),
  IN _category VARCHAR(16),  -- Filter: 'video', 'image', 'note', NULL = all
  IN _page INT
)
BEGIN
  DECLARE _offset BIGINT;
  DECLARE _range BIGINT;
  
  CALL pageToLimits(_page, _offset, _range);
  
  -- Temp table for all owned files
  DROP TABLE IF EXISTS _disk_usage_files;
  CREATE TEMPORARY TABLE _disk_usage_files (
    nid VARCHAR(16),
    filename VARCHAR(128),
    -- filepath VARCHAR(1000),
    category VARCHAR(16),
    filesize BIGINT,
    hub_id VARCHAR(16),
    hub_name VARCHAR(80),
    owner_id VARCHAR(16),
    ctime INT(11) UNSIGNED,
    mtime INT(11) UNSIGNED,
    KEY idx_category (category),
    KEY idx_filesize (filesize)
  );
  
  -- 1. Get files from user's personal hub (user's own database)
  INSERT INTO _disk_usage_files
  SELECT 
    m.id AS nid,
    m.user_filename AS filename,
    -- m.file_path AS filepath,
    m.category,
    m.filesize,
    _uid AS hub_id,
    'Personal' AS hub_name,
    m.owner_id,
    m.upload_time AS ctime,
    m.publish_time AS mtime
  FROM media m
  WHERE m.owner_id = _uid
    AND m.status = 'active'
    AND m.category NOT IN ('root', 'folder', 'hub');
  
  -- 2. Get files from hubs owned by user
  BEGIN
    DECLARE _finished INT DEFAULT 0;
    DECLARE _hub_id VARCHAR(16);
    DECLARE _hub_db VARCHAR(255);
    DECLARE _hub_name VARCHAR(80);
    
    DECLARE hub_cursor CURSOR FOR 
      SELECT h.id, e.db_name, h.name
      FROM yp.hub h
      INNER JOIN yp.entity e ON h.id = e.id
      WHERE h.owner_id = _uid
        AND e.status = 'active';
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    
    OPEN hub_cursor;
    
    hub_loop: LOOP
      FETCH hub_cursor INTO _hub_id, _hub_db, _hub_name;
      
      IF _finished = 1 THEN
        LEAVE hub_loop;
      END IF;
      
      -- Query files from this hub's database
      SET @sql = CONCAT(
        'INSERT INTO _disk_usage_files ',
        'SELECT m.id, m.user_filename, m.category, m.filesize, ',
        '''', _hub_id, ''', ''', _hub_name, ''', m.owner_id, ',
        'm.upload_time, m.publish_time ',
        'FROM ', _hub_db, '.media m ',
        'WHERE m.owner_id = ''', _uid, ''' ',
        'AND m.status = ''active'' ',
        'AND m.category NOT IN (''root'', ''folder'', ''hub'')'
      );
      
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
    END LOOP hub_loop;
    
    CLOSE hub_cursor;
  END;
  
  -- 3. Return summary statistics by category
  SELECT 
    category,
    COUNT(*) AS count,
    SUM(filesize) AS size
  FROM _disk_usage_files
  WHERE (_category IS NULL OR category = _category OR _category = '*')
  GROUP BY category;
  
  -- 4. Return total usage
  SELECT 
    SUM(filesize) AS total_used,
    COUNT(*) AS total_count
  FROM _disk_usage_files
  WHERE (_category IS NULL OR category = _category OR _category = '*');
  
  -- 5. Return paginated file list
  SELECT 
    nid,
    filename,
    -- filepath,
    category filetype,
    filesize,
    hub_id,
    hub_name,
    ctime,
    mtime
  FROM _disk_usage_files
  WHERE (_category IS NULL OR category = _category OR _category = '*')
  ORDER BY filesize DESC, mtime DESC
  LIMIT _offset, _range;
  
  DROP TABLE IF EXISTS _disk_usage_files;
  
END$

DELIMITER ;