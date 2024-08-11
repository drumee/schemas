DELIMITER $


DROP PROCEDURE IF EXISTS `mfs_pre_trash_next`$
CREATE PROCEDURE `mfs_pre_trash_next`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _modify_perm TINYINT(4)
)
BEGIN

  DECLARE _idx INT DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _shub_id VARCHAR(16);
  DECLARE _shub_db VARCHAR(40);
  DECLARE _user_db_name VARCHAR(255);


  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   

 START TRANSACTION;
  SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
  DROP TABLE IF EXISTS `_bin_media`; 
  CREATE TEMPORARY TABLE `_bin_media` (
        `filepath` VARCHAR(5000) NOT NULL DEFAULT '',
        `ownpath` VARCHAR(5000) NOT NULL DEFAULT '',
        `nid` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `pid` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `parent_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `home_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `capability` varchar(8) CHARACTER SET ascii DEFAULT '---',
        `owner_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `hub_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `status` varchar(20) NOT NULL DEFAULT 'active',
        `filename` varchar(128) DEFAULT NULL,
        `filesize` bigint(20) unsigned DEFAULT 0,
        `vhost` varchar(1024) DEFAULT NULL,
        `ext` varchar(100) CHARACTER SET ascii DEFAULT NULL,
        `ftype` varchar(16) NOT NULL DEFAULT 'other',
        `filetype` varchar(16) NOT NULL DEFAULT 'other',
        `mimetype` varchar(100) NOT NULL,
        `mtime` int(11) unsigned NOT NULL DEFAULT 0,
        `ctime` int(11) unsigned NOT NULL DEFAULT 0
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ;


  DROP TABLE IF EXISTS `_mytree`; 
  CREATE  TEMPORARY TABLE `_mytree` (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          user_filename varchar(128) DEFAULT NULL,
          extension varchar(100) CHARACTER SET ascii DEFAULT NULL);


  WHILE _idx < JSON_LENGTH(_nodes) DO 

        SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
        SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
        SELECT JSON_VALUE(@_node, "$.hub_id") INTO _shub_id;
        SELECT db_name FROM yp.entity WHERE id = _shub_id INTO _shub_db; 
        SELECT '' INTO @hub_path;
        SELECT '' INTO @hub_name;

        IF _uid != _shub_id THEN 
      
          SET @st = CONCAT("
            SELECT user_filename,parent_path
            FROM  ",_user_db_name,".media m 
            WHERE m.id='",_shub_id,"' INTO @hub_name , @parent_path"
          );

          PREPARE stmt FROM @st;
          EXECUTE stmt ;
          DEALLOCATE PREPARE stmt;
          SELECT CONCAT(@parent_path,'/',@hub_name) INTO @hub_path  ;
 
        END IF;  

        DELETE FROM _mytree;
        SET @st = CONCAT
        ( " 
           INSERT INTO _mytree
           WITH RECURSIVE mytree AS (
            SELECT id, parent_id ,user_filename, extension 
            FROM ",_shub_db,".media WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.id, m.parent_id ,m.user_filename, m.extension
            FROM ",_shub_db,".media AS m JOIN mytree AS t ON m.parent_id = t.id
          )
         SELECT id, parent_id ,user_filename, extension FROM mytree;");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT
        (
          "INSERT INTO ",_shub_db,".trash_media (sys_id,id,origin_id,owner_id,host_id,file_path,user_filename,parent_id,parent_path,extension,mimetype,
            category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
            metadata,caption,status,approval,rank)
            SELECT sys_id,id,origin_id,owner_id,host_id, file_path, user_filename ,parent_id,parent_path,extension,mimetype,
            category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
            metadata,caption,status,approval,rank
        FROM ",_shub_db,".media m WHERE id IN (SELECT id FROM _mytree);");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT
        (" UPDATE ",_shub_db,".trash_media SET STATUS = 'deleted' WHERE  id =", QUOTE(_nid),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

        SET @st = CONCAT ("DELETE FROM " ,_shub_db,".media WHERE id IN (SELECT id FROM _mytree);");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;


       SET @st = CONCAT("
              INSERT INTO _bin_media 
              (
              filepath,ownpath , nid, pid, parent_id, home_id, capability,
              owner_id, hub_id, status, filename, filesize,
              vhost, ext, ftype, filetype,
              mimetype, ctime, mtime
              )
              SELECT 
              CONCAT(@hub_path, m.file_path) as filepath,
              m.file_path as ownpath,
              m.id  AS nid,
              m.parent_id AS pid,
              m.parent_id AS parent_id,
              me.home_id AS home_id,
              ff.capability,
              me.id AS owner_id,
              me.id AS hub_id,
              m.status AS status,
              m.user_filename AS filename,
              m.filesize AS filesize,
              yp.vhost(me.id) AS vhost,
              m.extension AS ext,
              m.category AS ftype,
              m.category AS filetype,
              m.mimetype,
              m.upload_time AS ctime,
              m.publish_time AS mtime
            FROM ", _shub_db, ".trash_media m
              INNER JOIN yp.entity me ON me.db_name=", QUOTE(_shub_db),"
              LEFT JOIN yp.filecap ff ON m.extension=ff.extension
            WHERE m.status='deleted'  AND m.id =", QUOTE(_nid),"
            ");
         PREPARE stmt FROM @st;
         EXECUTE stmt ;
         DEALLOCATE PREPARE stmt;

      SELECT _idx + 1 INTO _idx;
  END WHILE; 
  COMMIT;
  SELECT * FROM _bin_media;
END$



--   NEED TO DELETE - GOPINATH 
DROP PROCEDURE IF EXISTS `mfs_pre_trash`$



DELIMITER ;

