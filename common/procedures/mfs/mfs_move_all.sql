DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_move_all`$
CREATE PROCEDURE `mfs_move_all`(
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


  DECLARE _is_root tinyint(2) ;
  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _file_name      VARCHAR(512) CHARACTER SET utf8; 
  DECLARE _metadata       JSON; 
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
  DECLARE _mtime          INT(11) UNSIGNED;
  DECLARE _isalink TINYINT(2) UNSIGNED DEFAULT 0;

  SELECT unix_timestamp() INTO _mtime;

  SELECT db_name, home_dir FROM yp.entity WHERE id=_recipient_id  
    INTO _dest_db, _dest_home_dir;

  DROP TABLE IF EXISTS  `_src_media`;
  CREATE TEMPORARY TABLE `_src_media` (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `is_root` boolean default 0 ,
    `id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `owner_id` varchar(16) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `metadata` JSON,
    `status`  varchar(20) ,
    `isalink` tinyint(2) unsigned NOT NULL DEFAULT '0',
    `category` VARCHAR(50) DEFAULT NULL,
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
    `permission`   tinyint(4) unsigned, 
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
    `type` varchar(10) DEFAULT 'cross' ,
    action varchar(16) DEFAULT NULL
  );

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _hub_id;

    SELECT db_name, home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db, _home_dir;
    
    IF _hub_id = _recipient_id   THEN
      SET @st = CONCAT('USE `', _hub_db, '`');
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3;
      DEALLOCATE PREPARE stmt3;

      SELECT user_filename, extension, category FROM media WHERE id=_nid INTO @user_filename, @extension, @category;
      SELECT unique_filename(_dest_id, @user_filename, @extension) INTO @user_filename;
      UPDATE media SET user_filename=@user_filename WHERE id=_nid;
      UPDATE media SET parent_id=_dest_id WHERE id=_nid;
      UPDATE media SET file_path=filepath(_nid), parent_path=parent_path(_nid) WHERE id=_nid;
      IF @category = 'folder' THEN
      	UPDATE media m, (
          WITH RECURSIVE __parent_tree AS
          (
            SELECT
              m0.sys_id,
              m0.id, 
              parent_path(m0.id) ppath,
              filepath(m0.id) path,
              m0.parent_id,
              m0.user_filename, 
              m0.extension, 
              m0.category
            FROM
              media m0
              WHERE m0.id = _nid 
            UNION ALL
              SELECT
              m1.sys_id,
              m1.id,
              parent_path(m1.id) ppath,
              filepath(m1.id) path,
              m1.parent_id,
              m1.user_filename, 
              m1.extension, 
              m1.category
            FROM
              media AS m1
            INNER JOIN __parent_tree AS t ON m1.parent_id = t.id AND 
              t.category IN('folder',  'root') 
          )
          SELECT * FROM __parent_tree) s
        SET m.parent_path = s.ppath, m.file_path = s.path 
        WHERE m.sys_id= s.sys_id;
      END IF;

      INSERT INTO _final_media (nid, category, src_db, des_db, `action`, `type`)
      SELECT _nid, NULL, _hub_db, _hub_db, 'show','same' ;


    ELSE 
      -- INSERT THE ROOT MEDIA's detail     
      DELETE FROM _src_media;
      SET @st = CONCAT( "INSERT INTO _src_media SELECT 
      null, 1, id, origin_id, ?, user_filename, metadata, status, isalink, category, parent_id,  
      extension, mimetype, filesize, geometry, null, null, 0, ?, ?, ? ,0
      FROM ", _hub_db ,".media m  WHERE  m.id =?");  
      PREPARE stmt FROM @st;
      EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _nid;
      DEALLOCATE PREPARE stmt;

      UPDATE _src_media SET new_parent_id = _dest_id  WHERE  id=_nid; 
      SELECT id FROM _src_media WHERE id = _nid INTO _temp_nid ;
    END IF ;

    WHILE _temp_nid IS NOT NULL DO
       
      SELECT seq, id, origin_id, user_filename, metadata,`status`, category,
        extension, mimetype, `geometry`, filesize, new_parent_id, is_root, 
        isalink
      FROM _src_media WHERE id =_temp_nid 
      INTO _seq,_id, _origin_id, _file_name, _metadata,_status, _category,
        _extension, _mimetype, _geometry, _file_size, _new_parent_id, _is_root,
        _isalink;        
     
      IF _category = 'hub' THEN
        
        IF _hub_id = _recipient_id   THEN
        
          SET @st = CONCAT("UPDATE ", _hub_db, ".media SET parent_id=? WHERE id =?");
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _new_parent_id, _temp_nid;
          DEALLOCATE PREPARE stmt3;

          SET @st = CONCAT("UPDATE ", _hub_db,
            ".media SET parent_path=", _hub_db,".parent_path(?) WHERE id=?"
          );
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid, _temp_nid;
          DEALLOCATE PREPARE stmt3;

          SET @st = CONCAT("UPDATE ", _hub_db,
            ".media SET file_path=filepath(id) WHERE id =?"
          );
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid;
          DEALLOCATE PREPARE stmt3;

        END IF;
      
        IF _hub_id <> _recipient_id AND _is_root = 0  THEN
          SET @st = CONCAT( "UPDATE ",_hub_db,
            ".media m , (SELECT id FROM ",_hub_db,".media WHERE  parent_id = '0') p SET 
            m.parent_id =p.id,
            m.parent_path = parent_path(?),
            m.file_path =  filepath(?)
            WHERE m.id =?");
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid, _temp_nid, _temp_nid;
          DEALLOCATE PREPARE stmt3;
        END IF;

      ELSE 
        -- INSERT THE CHILDERN if any    
        IF _category = 'folder' THEN
          SET @st = CONCAT( "INSERT INTO _src_media SELECT 
          null, 0, id, origin_id, ?, user_filename, metadata, status, isalink, category, parent_id, extension, 
          mimetype, filesize, geometry, null, null, 0, ?, ?, ?, 0 
          FROM ", _hub_db ,".media m WHERE m.parent_id =?");  
          PREPARE stmt FROM @st;
          EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _temp_nid;
          DEALLOCATE PREPARE stmt; 
        END IF ;

        SET @st = CONCAT("UPDATE yp.disk_usage SET size = IFNULL(size,0) - 
            (SELECT IFNULL(filesize,0) FROM " ,_hub_db, ".media  WHERE id =", QUOTE(_nid) ,") WHERE hub_id =",QUOTE( _hub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 


        SET @st = CONCAT( "DELETE FROM ",_hub_db,".media WHERE category <> 'hub' AND id=?");
        PREPARE stmt3 FROM @st;
        EXECUTE stmt3 USING _temp_nid;
        DEALLOCATE PREPARE stmt3;

        SET @args = JSON_OBJECT(
          "owner_id", _uid,
          "origin_id", _origin_id,
          "filename",_file_name,
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
      END IF;

        -- GET the Next unchecked media  ,       
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid ;
      SELECT NULL,NULL,NULL INTO _temp_nid, @temp_nid, @pid;
      SELECT id FROM _src_media WHERE is_checked =0 AND new_parent_id IS NOT NULL LIMIT 1 INTO _temp_nid ;

    END WHILE;
    

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'showone' 
      FROM _src_media WHERE seq=1; 

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'show' 
      FROM _src_media WHERE is_root=1;

    INSERT INTO _final_media (nid, category, src_mfs_root, des_id, des_mfs_root, `action`)
      SELECT id, category, CONCAT(home_dir, "/__storage__/"), new_id, CONCAT(_dest_home_dir, "/__storage__/"), 'move'  
      FROM _src_media WHERE category NOT IN ("folder","hub") ; 
 

    SELECT _idx + 1 INTO _idx;
  END WHILE;
  SELECT * FROM _final_media;
END $


DELIMITER ;

