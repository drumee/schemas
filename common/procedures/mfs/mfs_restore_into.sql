DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_restore_into_next`$
CREATE PROCEDURE `mfs_restore_into_next`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii 
)
BEGIN

  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dest_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _recipient_id VARCHAR(16);
  DECLARE _shub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _shub_db VARCHAR(40);
  DECLARE _dhub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dhub_db VARCHAR(40);
  DECLARE _dhome_dir VARCHAR(512) DEFAULT null;
  DECLARE _shome_dir VARCHAR(512) DEFAULT null;
  DECLARE _rows_affected INT DEFAULT 0;

  DECLARE exit handler for sqlexception
  BEGIN
    GET DIAGNOSTICS CONDITION 1
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @text = MESSAGE_TEXT;
    
    INSERT IGNORE INTO _restore_debug (step, details, error_state, error_msg) 
    VALUES ('EXCEPTION', 'SQL Exception caught', @sqlstate, CONCAT('Error ', @errno, ': ', @text));
    
    ROLLBACK;
    SELECT * FROM _restore_debug ORDER BY ts;
  END;

  -- Temp Tables
  DROP TABLE IF EXISTS _restore_debug;
  CREATE TEMPORARY TABLE _restore_debug (
    step VARCHAR(100),
    details TEXT,
    error_state VARCHAR(10) DEFAULT NULL,
    error_msg TEXT DEFAULT NULL,
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  INSERT INTO _restore_debug (step, details) 
  VALUES ('START', CONCAT('nodes=', _nodes, ', uid=', _uid));

  START TRANSACTION;

  DROP TABLE IF EXISTS _mytree; 
  CREATE TEMPORARY TABLE _mytree (
    id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    parent_id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    user_filename varchar(128) DEFAULT NULL,
    extension varchar(100) CHARACTER SET ascii DEFAULT NULL,
    category varchar(16) NOT NULL DEFAULT 'other',
    flag  TINYINT default 0,
    shub_id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    dhub_id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    shome_dir VARCHAR(512) DEFAULT null,
    dhome_dir VARCHAR(512) DEFAULT null,
    shub_db VARCHAR(40),
    dhub_db VARCHAR(40),
    is_show INT DEFAULT 0,
    nid varchar(16) CHARACTER SET ascii DEFAULT NULL
  );
  
  DROP TABLE IF EXISTS _disk_usage_restores;
  CREATE TEMPORARY TABLE _disk_usage_restores (
    hub_id varchar(16) CHARACTER SET ascii NOT NULL,
    delta bigint DEFAULT 0,
    PRIMARY KEY (hub_id)
  );

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
    SELECT JSON_VALUE(@_node, "$.hub_id") INTO _shub_id;
    SELECT JSON_VALUE(@_node, "$.pid") INTO _dest_id;
    SELECT JSON_VALUE(@_node, "$.recipient_id") INTO _dhub_id;
    
    SELECT db_name,home_dir FROM yp.entity WHERE id = _shub_id INTO _shub_db,_shome_dir; 
    SELECT db_name,home_dir FROM yp.entity WHERE id = _dhub_id INTO _dhub_db,_dhome_dir; 

    -- Build Tree
    SET @st = CONCAT(
      "INSERT INTO _mytree (id,parent_id,user_filename,extension,category,flag,nid)
       WITH RECURSIVE mytree AS 
      (
        SELECT id, ",QUOTE(_dest_id), " parent_id ,user_filename, extension,category,0 flag,", QUOTE(_nid ) ," nid   
        FROM  ",_shub_db,".trash_media WHERE id = ", QUOTE(_nid) , "
          UNION ALL
        SELECT m.id, m.parent_id ,m.user_filename, m.extension,m.category ,0 ,", QUOTE(_nid)," 
        FROM ",_shub_db,".trash_media AS m JOIN mytree AS t ON m.parent_id = t.id
      )
      SELECT id,parent_id,user_filename,extension,category,flag,nid FROM mytree;"
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt; 

    -- Flag Duplicates
    SET @st = CONCAT(
    "UPDATE _mytree m
    INNER JOIN ",_dhub_db,".media t  ON t.parent_id = m.parent_id 
          AND t.user_filename = m.user_filename 
          AND t.extension = m.extension
          AND m.nid =",QUOTE(_nid),"
    SET m.flag = 1;"
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    -- Insert Normal
    SET @st = CONCAT(
    "INSERT INTO ",_dhub_db,".media 
        (sys_id,id,origin_id,owner_id,host_id,file_path,user_filename,parent_id,parent_path,extension,mimetype,
        category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
        metadata,caption,status,approval,rank)
    SELECT 
        NULL,m.id,m.origin_id,m.owner_id,m.host_id,NULL, m.user_filename ,s.parent_id,'',m.extension,m.mimetype,
        m.category,m.isalink,m.filesize,m.geometry,m.publish_time,m.upload_time,m.last_download,m.download_count,
        m.metadata,m.caption,'active',m.approval,m.rank
    FROM ",_shub_db,".trash_media m 
    INNER JOIN _mytree s ON s.id = m.id
    WHERE s.flag =0  AND s.nid =",QUOTE(_nid),";"
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    -- Insert Duplicates
    SET @st = CONCAT(
      "INSERT INTO ",_dhub_db,".media (sys_id,id,origin_id,owner_id,host_id,file_path,user_filename,parent_id,parent_path,extension,mimetype,
          category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
          metadata,caption,status,approval,rank)
      SELECT NULL,m.id,m.origin_id,m.owner_id,m.host_id,NULL, ",_dhub_db,".unique_filename(s.parent_id, m.user_filename, m.extension) ,s.parent_id,'',m.extension,m.mimetype,
          m.category,m.isalink,m.filesize,m.geometry,m.publish_time,m.upload_time,m.last_download,m.download_count,
          m.metadata,m.caption,'active',m.approval,m.rank
      FROM ",_shub_db,".trash_media m 
      INNER JOIN _mytree s ON s.id = m.id
      WHERE flag =1 AND s.nid =",QUOTE(_nid),";"
      );
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    -- Update Paths
    SET @st = CONCAT("UPDATE ", _dhub_db, 
          ".media SET parent_path=",_dhub_db,".parent_path(id) WHERE id IN (SELECT id FROM _mytree  WHERE nid =",QUOTE(_nid) ,");"
        );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @st = CONCAT("UPDATE ", _dhub_db, 
          ".media SET file_path =clean_path(concat(parent_path, '/', user_filename, '.', extension)) WHERE id IN (SELECT id FROM _mytree  WHERE nid =", QUOTE(_nid),");"
        );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Calc Size
    SET @total_size = 0;
    SET @st = CONCAT("SELECT IFNULL(SUM(filesize),0) FROM ", _shub_db, ".trash_media WHERE id IN (SELECT id FROM _mytree WHERE nid =", QUOTE(_nid),") INTO @total_size");
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    INSERT INTO _disk_usage_restores (hub_id, delta)
    VALUES (_shub_id, -@total_size)
    ON DUPLICATE KEY UPDATE delta = delta - @total_size;
    
    INSERT INTO _disk_usage_restores (hub_id, delta)
    VALUES (_dhub_id, @total_size)
    ON DUPLICATE KEY UPDATE delta = delta + @total_size;

    -- Delete from Trash
    SET @st = CONCAT(
    "DELETE FROM ",_shub_db,".trash_media WHERE id IN (SELECT id FROM _mytree  WHERE nid =", QUOTE(_nid) ,");"
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    UPDATE  _mytree SET is_show = 1  WHERE id =_nid;
    DELETE FROM _mytree WHERE category IN ("hub") AND is_show =0;
    
    SELECT NULL,NULL INTO _dhub_db ,_shub_db;
    SELECT _idx + 1 INTO _idx;
  END WHILE; 

  -- Batch Update Disk Usage (With Trigger Protection)
  BEGIN
    DECLARE _finished INT DEFAULT 0;
    DECLARE _update_hub_id VARCHAR(16);
    DECLARE _update_delta BIGINT;
    
    DECLARE update_cursor CURSOR FOR 
      SELECT hub_id, delta FROM _disk_usage_restores;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    DECLARE CONTINUE HANDLER FOR 1264 BEGIN END; 
    
    OPEN update_cursor;
    update_loop: LOOP
      FETCH update_cursor INTO _update_hub_id, _update_delta;
      IF _finished = 1 THEN LEAVE update_loop; END IF;
      
      IF _update_delta < 0 THEN
         UPDATE yp.disk_usage 
         SET size = IF(IFNULL(size, 0) < ABS(_update_delta), 0, IFNULL(size, 0) - ABS(_update_delta))
         WHERE hub_id = _update_hub_id;
      ELSE
         UPDATE yp.disk_usage 
         SET size = IFNULL(size, 0) + _update_delta
         WHERE hub_id = _update_hub_id;
      END IF;
    END LOOP;
    CLOSE update_cursor;
  END;

  COMMIT;

  -- TRIM TRAILING SLASHES TO PREVENT '//'
  SELECT 
      id nid,  
      CONCAT(TRIM(TRAILING '/' FROM _shome_dir), "/__storage__/") src_mfs_root,  
      id des_id, 
      CONCAT(TRIM(TRAILING '/' FROM _dhome_dir), "/__storage__/") des_mfs_root,
      dhub_id dest_hub_id, 
      dhub_db dest_db_name, 
      'move' `action`
  FROM _mytree WHERE category NOT IN ("folder","hub") 
    UNION ALL
  SELECT 
      id nid,  
      CONCAT(TRIM(TRAILING '/' FROM _shome_dir), "/__storage__/") src_mfs_root,  
      id des_id, 
      CONCAT(TRIM(TRAILING '/' FROM _dhome_dir), "/__storage__/") des_mfs_root,
      dhub_id dest_hub_id, 
      dhub_db dest_db_name, 
      'show' `action`
  FROM _mytree WHERE is_show = 1; 

END$

DELIMITER ;