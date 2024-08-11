DELIMITER $

--   NEED TO DELETE - GOPINATH 
-- =========================================================
-- TRASHING A NODE 
-- =========================================================
 
DROP PROCEDURE IF EXISTS `mfs_trash_node`$
-- CREATE PROCEDURE `mfs_trash_node`(
--   IN _nid VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _pid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _src_type VARCHAR(100);
--   DECLARE _file_name VARCHAR(1024);
--   DECLARE _node_path VARCHAR(255);
  
--   DECLARE _root_id VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _bound VARCHAR(16);
--   DECLARE _lvl INT;
--   DECLARE _origin_id VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _tempid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _chk_tempid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _temp_file_path VARCHAR(6000);
--   DECLARE _temp_parent_id VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _temp_user_filename VARCHAR(1024);

--   DECLARE t_id VARCHAR(16) CHARACTER SET ascii;

--   DROP TABLE IF EXISTS  _folder_media;
--   CREATE TEMPORARY TABLE _folder_media (
--     `seq`  int NOT NULL AUTO_INCREMENT,  
--     `id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
--     `parent_id` varchar(16) CHARACTER SET ascii NULL DEFAULT '',
--     `user_filename` varchar(128) DEFAULT NULL,
--     `is_checked` boolean default 0,
--     PRIMARY KEY `seq`(`seq`) 
--     );


--   DROP TABLE IF EXISTS _compare_media; 
--   CREATE TEMPORARY TABLE _compare_media (
--     seq  int NOT NULL AUTO_INCREMENT, 
--     id varchar(16) CHARACTER SET ascii DEFAULT NULL,
--     parent_id varchar(16) CHARACTER SET ascii DEFAULT null,
--     user_filename varchar(128) DEFAULT NULL, 
--     file_path VARCHAR(1024) DEFAULT NULL,
--     parent_path VARCHAR(1024) DEFAULT NULL,
--     is_checked boolean default 0,
--     is_in_trace  boolean default 0,
--     t_id varchar(16) CHARACTER SET ascii DEFAULT NULL,
--     t_parent_id varchar(16) CHARACTER SET ascii DEFAULT null,
--     category VARCHAR(50) DEFAULT NULL,
--     PRIMARY KEY `seq`(`seq`)  
--   );

--   SELECT id FROM yp.entity where db_name = DATABASE() INTO _origin_id;
--   SELECT id FROM media WHERE  parent_id='0' INTO _root_id;

--   SELECT  parent_id FROM media where id =_nid INTO _tempid;

--   WHILE ( IFNULL(_lvl,0) <=100 AND _root_id  <> _tempid  AND _tempid IS NOT NULL ) DO
--     INSERT INTO _folder_media
--     SELECT null,id,parent_id, user_filename,0 FROM media where id = _tempid  ;
--     SELECT parent_id FROM media where id =_tempid INTO _tempid;
--     SELECT IFNULL(_lvl,0) +1  INTO _lvl  ; 
--   END WHILE;

--   SELECT MAX(seq) FROM _folder_media  INTO _lvl; 
  
--   SELECT clean_path(CONCAT( IFNULL(_temp_file_path,''), '/', user_filename )) , user_filename 
--   FROM  _folder_media 
--   WHERE seq = _lvl
--   INTO  _temp_file_path,_temp_user_filename;

--   SELECT node_id_from_path('/__trash__') INTO _temp_parent_id; 

--   START TRANSACTION;
--     WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) do
--       SELECT NULL INTO _chk_tempid ;
--       SELECT id FROM media WHERE file_path = clean_path(CONCAT('/__trash__',_temp_file_path)) INTO _chk_tempid;
--       SELECT _lvl - 1  INTO _lvl  ;  

--       IF _chk_tempid IS NULL THEN 
--         SET @st = CONCAT("CALL mfs_new_node(
--           ?, ?, ?, ?, 'folder', '', 'folder', NULL, NULL, 0)"
--         );
--         PREPARE stmt2 FROM @st;
--         EXECUTE stmt2 USING _origin_id, _origin_id, _temp_user_filename, _temp_parent_id;
--         DEALLOCATE PREPARE stmt2;

--       END IF;

--       SELECT id FROM media WHERE file_path = clean_path(CONCAT('/__trash__',_temp_file_path)) INTO _temp_parent_id;
--       SELECT clean_path(CONCAT( IFNULL(_temp_file_path,''), '/', user_filename )) , user_filename 
--       FROM  _folder_media 
--       WHERE seq = _lvl
--       INTO  _temp_file_path,_temp_user_filename;
--     END WHILE;


--     SELECT _temp_parent_id INTO _pid;
    
--     INSERT INTO _compare_media (seq,id,parent_id, user_filename,file_path,parent_path,is_checked,is_in_trace,category)
--     SELECT null,id,parent_id, user_filename,clean_path(concat(parent_path(id), '/', user_filename, '.', extension)),parent_path(id),0,0,category 
--     FROM media where id = _nid;
    
--     SELECT id FROM _compare_media WHERE id = _nid AND is_checked =0 LIMIT 1 INTO _tempid ;
    
--     WHILE (_tempid IS NOT NULL) do
  
--       INSERT INTO _compare_media (seq,id,parent_id, user_filename,file_path,parent_path,is_checked,is_in_trace,category)
--       SELECT NULL,id,parent_id, user_filename,clean_path(concat(parent_path(id), '/', user_filename, '.', extension)),parent_path(id),0,0,category 
--       FROM media where parent_id = _tempid;
            
--       UPDATE _compare_media SET is_checked = 1 WHERE id = _tempid ;
              
--       SELECT NULL INTO _tempid ;
--       SELECT id FROM _compare_media WHERE is_checked =0 LIMIT 1 INTO _tempid ;
--     END WHILE;
  
--     --  IF ALREADY AVAILBE IN TRASH  THEN FIND t_id (trash's media id ) & t_parent_id (trash parent media id)
--     UPDATE _compare_media c SET t_id = (SELECT id from  media where file_path = clean_path(CONCAT('/__trash__', c.file_path)));
--     UPDATE _compare_media c SET t_parent_id = (SELECT parent_id FROM media where id = c.t_id);
--     UPDATE _compare_media c SET t_parent_id = _pid WHERE seq=1 AND t_parent_id is null;
--     DROP TABLE IF EXISTS _compare_media1; 
--     CREATE TEMPORARY TABLE _compare_media1 AS SELECT * FROM _compare_media;

--     -- UPDATE remining t_parent_id (trash parent media id) with self join
--     UPDATE _compare_media CM SET t_parent_id = (SELECT CM1.t_id FROM _compare_media1 CM1 where CM1.id = CM.parent_id 
--     AND CM1.t_parent_id IS NOT NULL LIMIT 1) WHERE CM.t_parent_id IS NULL ;


--     UPDATE media M , _compare_media CM
--     SET M.parent_id = CM.t_parent_id,
--     status = 'deleted'
--     WHERE 
--     M.id = CM.id
--     AND CM.t_id IS NULL AND CM.t_parent_id IS NOT NULL;

--     UPDATE media M, _compare_media CM
--     SET M.parent_id = CM.t_parent_id,
--     M.user_filename =  unique_filename(CM.t_parent_id, CM.user_filename, M.extension),
--     status = 'deleted'
--     WHERE 
--     M.id = CM.id
--     AND CM.t_id IS NOT NULL AND CM.t_parent_id IS NOT NULL AND CM.category <> 'folder' ;

--     UPDATE media 
--     SET parent_path = parent_path(id),file_path = clean_path(concat(parent_path(id), '/', user_filename, '.', extension)),
--     status = 'deleted'
--     WHERE id in (SELECT id from _compare_media );


--     UPDATE media  SET status = 'deleted' WHERE id in (SELECT C.t_id FROM _compare_media C WHERE C.category = 'folder' 
--     AND C.t_id IS NOT NULL AND  C.t_parent_id IS NOT NULL);

--     DELETE FROM media  WHERE id IN (SELECT C.id FROM _compare_media C WHERE C.category = 'folder' 
--     AND C.t_id IS NOT NULL AND  C.t_parent_id IS NOT NULL );
--   IF _root_id <> _nid THEN 
--     COMMIT;
--   ELSE 
--     ROLLBACK;
--   END IF;
  
  
--   DROP TABLE IF EXISTS  _folder_media;
--   DROP TABLE IF EXISTS _compare_media; 
--   DROP TABLE IF EXISTS _compare_media1; 

-- END $


DELIMITER ;
