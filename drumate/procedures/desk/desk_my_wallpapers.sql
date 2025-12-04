-- File: schemas/drumate/procedures/desk/desk_my_wallpapers.sql
-- Purpose: Get combined list of user + system wallpapers with pagination

DELIMITER $

DROP PROCEDURE IF EXISTS `desk_my_wallpapers`$

CREATE PROCEDURE `desk_my_wallpapers`(
  IN _user_id VARCHAR(16),
  IN _page INT
)
BEGIN
  DECLARE _offset BIGINT;
  DECLARE _range BIGINT;
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _system_host VARCHAR(255);
  DECLARE _system_path VARCHAR(1024);
  DECLARE _system_hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _system_folder_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _system_hub_db VARCHAR(255);
  DECLARE _wallpaper_config JSON;
  
  CALL pageToLimits(_page, _offset, _range);
  
  SELECT db_name FROM yp.entity WHERE id = _user_id INTO _user_db_name;
  
  -- Get system wallpaper config from sysconf
  -- Format: {"host":"xxx.drumee.in","nid":"/Wallpapers","vhost":"xxx","path":"/Wallpapers"}
  SELECT conf_value INTO _wallpaper_config
  FROM yp.sys_conf
  WHERE conf_key = 'wallpaper';
  
  IF _wallpaper_config IS NOT NULL THEN
    SELECT 
      JSON_VALUE(_wallpaper_config, '$.host'),
      JSON_VALUE(_wallpaper_config, '$.path')
    INTO _system_host, _system_path;
    
    -- Get hub_id from host (host is the hub_id in this case)
    SELECT e.id, e.db_name 
    FROM yp.entity e
    INNER JOIN yp.vhost v ON v.id = e.id
    WHERE v.fqdn = _system_host
    INTO _system_hub_id, _system_hub_db;
    
    -- Get folder nid from path using node_id_from_path function
    IF _system_hub_db IS NOT NULL AND _system_path IS NOT NULL THEN
      SET @sql = CONCAT(
        'SELECT ', _system_hub_db, '.node_id_from_path(''', _system_path, ''') INTO @system_folder_nid'
      );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT @system_folder_nid INTO _system_folder_nid;
    END IF;
  END IF;
  
  -- Create temp table for combined results
  DROP TABLE IF EXISTS _temp_wallpapers;
  CREATE TEMPORARY TABLE _temp_wallpapers (
    nid VARCHAR(16) CHARACTER SET ascii,
    filename VARCHAR(512),
    ext VARCHAR(100),
    category VARCHAR(50),
    ftype VARCHAR(50),
    mimetype VARCHAR(100),
    filesize BIGINT,
    ctime INT UNSIGNED,
    mtime INT UNSIGNED,
    source VARCHAR(10),  -- 'user' or 'system'
    hub_id VARCHAR(16) CHARACTER SET ascii,
    vhost VARCHAR(255),
    sort_order INT  -- For sorting: user files first
  );
  
  -- Insert user wallpapers
  IF _user_db_name IS NOT NULL THEN
    SET @sql = CONCAT('
      INSERT INTO _temp_wallpapers 
      (nid, filename, ext, mimetype, filesize, ctime, mtime, source, hub_id, vhost, sort_order)
      SELECT 
        m.id AS nid,
        m.user_filename AS filename,
        m.extension AS ext,
        m.mimetype,
        m.filesize,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        ''user'' AS source,
        ''', _user_id, ''' AS hub_id,
        v.fqdn AS vhost,
        1 AS sort_order
      FROM ', _user_db_name, '.media m
      LEFT JOIN yp.vhost v ON v.id = ''', _user_id, '''
      WHERE m.parent_id IN (
        SELECT id FROM ', _user_db_name, '.media 
        WHERE category = ''folder'' 
          AND JSON_VALUE(metadata, ''$.folder_type'') = ''wallpapers''
      )
      AND m.category = ''image''
      AND m.extension IN (''jpg'', ''jpeg'', ''png'', ''webp'', ''gif'', ''svg'')
      AND m.status NOT IN (''hidden'', ''deleted'')
    ');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  
  -- Insert system wallpapers
  IF _system_hub_db IS NOT NULL AND _system_folder_nid IS NOT NULL THEN
    SET @sql = CONCAT('
      INSERT INTO _temp_wallpapers 
      (nid, filename, ext, mimetype, filesize, ctime, mtime, source, hub_id, vhost, sort_order)
      SELECT 
        m.id AS nid,
        m.user_filename AS filename,
        m.extension AS ext,
        m.mimetype,
        m.filesize,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        ''system'' AS source,
        ''', _system_hub_id, ''' AS hub_id,
        v.fqdn AS vhost,
        2 AS sort_order
      FROM ', _system_hub_db, '.media m
      LEFT JOIN yp.vhost v ON v.id = ''', _system_hub_id, '''
      WHERE m.parent_id = ''', _system_folder_nid, '''
        AND m.category = ''image''
        AND m.extension IN (''jpg'', ''jpeg'', ''png'', ''webp'', ''gif'', ''svg'')
        AND m.status NOT IN (''hidden'', ''deleted'')
    ');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  
  -- Return paginated results (user wallpapers first, then system)
  SELECT 
    t.nid,
    t.filename,
    t.ext,
    t.mimetype,
    t.filesize,
    t.ctime,
    t.mtime,
    t.source,
    t.hub_id,
    t.vhost,
    fc.capability,
    COALESCE(t.ftype, fc.category) AS ftype,
    COALESCE(t.ftype, fc.category) AS filetype
  FROM _temp_wallpapers t
  LEFT JOIN yp.filecap fc ON t.ext = fc.extension
  ORDER BY t.sort_order ASC, t.ctime DESC
  LIMIT _offset, _range;
  
  DROP TABLE IF EXISTS _temp_wallpapers;
  
END$

DELIMITER ;