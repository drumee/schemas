DELIMITER $



-- =========================================================
-- 
-- =========================================================


DROP PROCEDURE IF EXISTS `mfs_copy_all`$
CREATE PROCEDURE `mfs_copy_all`(
  IN _nodes JSON,
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(40);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _dest_db VARCHAR(50);
  DECLARE _dest_home_dir VARCHAR(512);
  DECLARE _temp_nid  VARCHAR(16);
  -- DECLARE _is_shared_hub  INTEGER DEFAULT 0;


  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);   
  DECLARE _new_parent_id  VARCHAR(16);  
  DECLARE _metadata       JSON; 
  DECLARE _isalink         tinyint(2) unsigned DEFAULT 0;


  SELECT db_name, home_dir FROM yp.entity 
    WHERE id=_recipient_id INTO _dest_db, _dest_home_dir;

  DROP TABLE IF EXISTS  _src_media;
  CREATE TEMPORARY TABLE `_src_media` (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `is_root` boolean default 0 ,
    `id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `owner_id` varchar(16) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `metadata` JSON,
    `isalink`  tinyint(2) unsigned, 
    `category`      VARCHAR(50) DEFAULT NULL,
    `parent_id` varchar(16) DEFAULT null,
    `extension` varchar(100) NOT NULL DEFAULT '',
    `mimetype` varchar(100) NOT NULL,
    `filesize` int(20) unsigned NOT NULL DEFAULT '0',
    `geometry` varchar(200) NOT NULL DEFAULT '0x0',
    `new_id` varchar(16) DEFAULT NULL,  
    `new_parent_id` varchar(16) DEFAULT '' ,
    `is_checked` boolean default 0 ,
    `home_dir` VARCHAR(512) DEFAULT null,
    `db_name` VARCHAR(512) DEFAULT null,
    `hub_id` VARCHAR(16) DEFAULT null,
    PRIMARY KEY `seq`(`seq`)  
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

  DROP TABLE IF EXISTS _final_media; 
  CREATE TEMPORARY TABLE `_final_media` (
    nid varchar(16) DEFAULT NULL,  
    category varchar(50) DEFAULT NULL,  
    src_mfs_root varchar(1024) DEFAULT NULL,  
    src_db varchar(160) DEFAULT NULL,  
    des_id varchar(16) DEFAULT NULL,  
    des_mfs_root varchar(1024) DEFAULT NULL,  
    des_db varchar(160) DEFAULT NULL,  
    action varchar(16) DEFAULT NULL
  );




  WHILE _idx < JSON_LENGTH(_nodes) DO 
    DELETE FROM _src_media;
    -- GET THE root media & hub from the node list
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _hub_id;

    SELECT db_name, home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db ,_home_dir;
    
    -- INSERT THE ROOT MEDIA's detail     
    SET @st = CONCAT("
      INSERT INTO _src_media SELECT 
      null, 1, id, origin_id, ?, user_filename,metadata,isalink, category, parent_id, 
      extension, mimetype, filesize, geometry, null, null, 0, ?, ?, ? 
      FROM ", _hub_db,".media m  WHERE category <> 'hub' AND m.id =?
    ");  
    PREPARE stmt FROM @st;
    EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _nid;
    DEALLOCATE PREPARE stmt;

    UPDATE _src_media SET new_parent_id = _dest_id  WHERE  id=_nid; 
    SELECT id FROM _src_media WHERE id = _nid INTO _temp_nid ;

     WHILE _temp_nid IS NOT NULL DO
       
      SELECT seq,id,origin_id,user_filename,metadata, isalink,category,
        extension,mimetype,`geometry`,filesize,new_parent_id 
      FROM _src_media WHERE id =_temp_nid 
      INTO _seq,_id,_origin_id,_file_name,_metadata, _isalink,_category,
        _extension,_mimetype,_geometry,_file_size, _new_parent_id;        
    

      -- INSERT THE CHILDERN if any    
      IF _category = 'folder' THEN
        SET @st = CONCAT("
          INSERT INTO _src_media SELECT 
          null, 0, id, origin_id, ?, user_filename, null, 0, category, parent_id, extension, 
          mimetype, filesize, geometry, null, null, 0, ?, ?, ?  
          FROM ", _hub_db,".media m WHERE status <> 'hidden' AND  category <> 'hub' AND m.parent_id =?
        ");  
        PREPARE stmt FROM @st;
        EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _temp_nid;
        DEALLOCATE PREPARE stmt; 
      END IF ;

      SET @args = JSON_OBJECT(
        "owner_id", _uid,
        "origin_id", _origin_id,
        "filename", _file_name,
        "pid", _new_parent_id,
        "category", _category,
        "ext", _extension,
        "mimetype", _mimetype,
        "filesize", _file_size,
        "geometry", _geometry,
        "isalink", _isalink
      );

      SET @results = JSON_OBJECT();
      SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");

      PREPARE stmt2 FROM @st;
      EXECUTE stmt2 USING @args, _metadata;
      DEALLOCATE PREPARE stmt2;

      SELECT JSON_VALUE(@results, "$.id") INTO @temp_nid;
      SELECT JSON_VALUE(@results, "$.pid") INTO @pid;

      UPDATE _src_media SET new_id =@temp_nid  WHERE seq =_seq ; 
      UPDATE _src_media SET new_parent_id =  @temp_nid WHERE parent_id = _temp_nid; 
      

      -- GET the Next unchecked media  ,       
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid ;
      SELECT NULL,NULL,NULL INTO _temp_nid ,@temp_nid,@pid;
      SELECT id FROM _src_media WHERE is_checked =0 
        AND new_parent_id IS NOT NULL LIMIT 1 INTO _temp_nid ;

     END WHILE;

    SELECT _idx + 1 INTO _idx;
    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'showone' 
      FROM _src_media WHERE seq=1; 

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'show' 
      FROM _src_media WHERE is_root=1;

    INSERT INTO _final_media (nid, category, src_mfs_root, des_id, des_mfs_root, `action`)
      SELECT id, category, CONCAT(home_dir, "/__storage__/"), new_id, CONCAT(_dest_home_dir, "/__storage__/"), 'copy'  
      FROM _src_media WHERE category NOT IN ("folder","hub") ; 
  END WHILE;

  SELECT * FROM _final_media;
  DROP TABLE IF EXISTS `_src_media`;
  DROP TABLE IF EXISTS `_final_media`;


END $

DELIMITER ;
