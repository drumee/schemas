DELIMITER $

-- ==============================================================
-- 
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `mfs_count_new`$
CREATE PROCEDURE `mfs_count_new`(
  IN _node_id VARCHAR(16), 
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _tempid VARCHAR(16);
  DECLARE _category VARCHAR(16);
  DECLARE _lvl INT;
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);


    SELECT id FROM yp.entity WHERE db_name = database() INTO  _hub_id;
  
    DROP TABLE IF EXISTS _show_node; 
    CREATE TEMPORARY TABLE _show_node (
     `seq`  int NOT NULL AUTO_INCREMENT,
     `id` varchar(16),
     `parent_id` varchar(16), 
     `category` varchar(16) ,
      PRIMARY KEY `seq`(`seq`) 
    );

    INSERT INTO _show_node 
    (id, parent_id ,category)
    WITH RECURSIVE mytree AS 
    ( 
      SELECT id, parent_id ,category
      FROM media WHERE id = _node_id
        UNION ALL
      SELECT m.id,m.parent_id ,m.category
      FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
    ) SELECT id, parent_id ,category FROM mytree;
    -- SELECT * FROM _show_node;
    
 
    SELECT MAX(seq) FROM _show_node  INTO _lvl; 
    SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid  ,_category;

    SET @_new_chat = 0;
    SET @_new_file = 0;
    WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) DO
        IF (_category = 'hub') THEN
        SET @_temp_file_count = 0;
        SET @_temp_read_cnt = 0; 
        SET @_temp_result = NULL;
        SELECT db_name FROM yp.entity WHERE id = _tempid
        INTO _hub_db_name; 
        SET @s = CONCAT(
          "SELECT IFNULL(SUM(is_new(metadata, owner_id, ?)), 0) FROM ", _hub_db_name ,
          ".media WHERE file_path not REGEXP '^/__(chat|trash)__' INTO @_temp_file_count"
         );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _uid;
        DEALLOCATE PREPARE stmt;


        SET @st = CONCAT('CALL ', _hub_db_name ,'.room_detail(?,?)');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING  JSON_OBJECT('uid',_uid ) , @_temp_result ;
        DEALLOCATE PREPARE stamt; 
      
        SELECT JSON_UNQUOTE(JSON_EXTRACT( @_temp_result, "$.read_cnt")) INTO @_temp_read_cnt;
    

        SELECT @_temp_file_count + @_new_file INTO @_new_file;
        SELECT @_temp_read_cnt + @_new_chat INTO @_new_chat;    
      END IF;
    
     
      SELECT _lvl - 1  INTO _lvl; 
      SELECT NULL, NULL INTO _tempid,_category;
      SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid,_category;

    END WHILE;

  SELECT SUM(is_new(m.metadata, owner_id, _uid)) FROM _show_node 
  INNER JOIN media m USING(id)  INTO @_file_count;
  SELECT IFNULL(GROUP_CONCAT(id), _hubs) FROM _show_node 
  WHERE category='hub' INTO @_hubs;
 

  SELECT _node_id nid, _uid `uid`, _hub_id AS hub_id, @_hubs hubs,
    @_new_chat new_chat, @_new_file AS count, @_new_file new_file,
    CAST((@_new_chat + @_new_file) as UNSIGNED INTEGER) notify;
  


END $

-- DROP PROCEDURE IF EXISTS `mfs_count_new`$
-- CREATE PROCEDURE `mfs_count_new`(
--   IN _node_id VARCHAR(16), 
--   IN _uid VARCHAR(16)
-- )
-- BEGIN
 
--   DECLARE _range bigint;
--   DECLARE _offset bigint;
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _hub_id VARCHAR(16);
--   DECLARE _src_db_name VARCHAR(255);
--   DECLARE _this_db_name VARCHAR(255);
--   DECLARE _finished       INTEGER DEFAULT 0; 
--   DECLARE _nid VARCHAR(16);  
--   DECLARE _parent_id VARCHAR(16);  
--   DECLARE _hub_db_name VARCHAR(255);
--   DECLARE _ftype VARCHAR(255);
--   DECLARE _pid VARCHAR(16);
--   DECLARE _category VARCHAR(255);
--   DECLARE _etype VARCHAR(255);
--   DECLARE _count INTEGER DEFAULT 0; 
--   DECLARE _hubs MEDIUMTEXT DEFAULT NULL; 

--   SELECT id FROM media where parent_id='0' INTO _home_id;
--   SELECT category, parent_id, is_new(metadata, owner_id, _uid) FROM media where id=_node_id 
--     INTO _category, _pid, @_file_count;
--   SELECT `type`, id FROM yp.entity WHERE db_name = database() INTO _etype, _hub_id;
  
--   DROP TABLE IF EXISTS _show_node;
--   SELECT database() INTO _this_db_name;
--   CREATE TEMPORARY TABLE _show_node  AS  
--   SELECT 
--     m.id  AS nid,
--     _this_db_name AS src_db_name,
--     m.category AS ftype,
--     he.db_name hub_db_name
--   FROM media m
--     INNER JOIN yp.entity me ON me.db_name=_this_db_name
--     LEFT JOIN yp.entity he ON m.id = he.id AND me.area IN('private', 'dmz', 'public')
--   WHERE m.parent_id=_node_id AND m.file_path not REGEXP '^/__(chat|trash)__' ;

--   ALTER table _show_node ADD actual_home_id VARCHAR(16) ;
--   ALTER table _show_node ADD hubs MEDIUMTEXT ;
--   ALTER table _show_node ADD nodes MEDIUMTEXT ;
--   ALTER table _show_node ADD notify INTEGER;
--   ALTER table _show_node ADD chat INTEGER;

--   DROP TABLE IF EXISTS _outerfile; 
--   CREATE TEMPORARY TABLE `_outerfile` (
--     seq  int NOT NULL AUTO_INCREMENT,
--     id varchar(16) DEFAULT NULL, 
--     parent_id varchar(16) DEFAULT NULL, 
--     file_path varchar(1000),
--     user_filename varchar(128),
--     category varchar(128),
--     `status` varchar(128),
--     nid varchar(16) DEFAULT NULL, 
--     PRIMARY KEY `seq`(`seq`),
--     UNIQUE KEY `id`(`id`)  
--   );

--   SET @_new_file = @_file_count;
--   SET @_new_chat = 0;
--   SET @_chat_count = 0;
--   SELECT CONCAT('$._seen_.', _uid) INTO @_seen_uid;

--   IF (_etype='hub') THEN 

--     SELECT IFNULL(SUM(is_new(metadata, author_id, _uid)), 0) FROM channel
--       INTO @_new_chat;
--   END IF;

--   BEGIN
--     DECLARE dbcursor CURSOR FOR SELECT nid, src_db_name, ftype, hub_db_name FROM _show_node;
--     DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
--     OPEN dbcursor;
--        FETCH dbcursor INTO _nid, _src_db_name, _ftype, _hub_db_name;
--        WHILE NOT _finished DO 
--         SET @perm = 0;
--         SELECT NULL INTO @actual_home_id ;


--         DROP TABLE IF EXISTS _innerfile; 
--         CREATE TEMPORARY TABLE `_innerfile` LIKE _outerfile;
--         SET @_file_count = 0;
--         IF _ftype = 'hub' AND _hub_db_name IS NOT NULL  THEN 

--           SET @s = CONCAT(
--             "SELECT IFNULL(SUM(is_new(metadata, owner_id, ?)), 0) FROM ", _hub_db_name ,
--             ".media WHERE file_path not REGEXP '^/__(chat|trash)__' INTO @_file_count"
--           );
--           PREPARE stmt FROM @s;
--           EXECUTE stmt USING _uid;
--           DEALLOCATE PREPARE stmt;

--           SET @s2 = CONCAT(
--             "SELECT IFNULL(SUM(is_new(metadata, author_id, ?)), 0) FROM ", _hub_db_name ,
--             ".channel INTO @_chat_count"
--           );
--           PREPARE stmt2 FROM @s2;
--           EXECUTE stmt2 USING _uid;
--           DEALLOCATE PREPARE stmt2;
--           SELECT @_file_count + @_new_file INTO @_new_file;
--           SELECT @_chat_count + @_new_chat INTO @_new_chat;
--           -- SELECT IF(@_chat_count, @_file_count + @_chat_count, @_file_count) INTO @_notify;
--           SELECT IF(_hubs IS NULL, _nid, CONCAT(_hubs, ',', _nid)) INTO _hubs;

--         ELSE 
--           IF _src_db_name IS NOT NULL THEN 
--             SET @_new_file = 0;
--             IF _ftype = 'folder' THEN
--               REPLACE INTO _innerfile (id, parent_id, file_path, user_filename, category, `status`) 
--                 WITH RECURSIVE myfile AS 
--                 (
--                   SELECT id, parent_id, file_path, user_filename, category, `status`
--                     FROM media WHERE id = _nid AND file_path not REGEXP '^/__(chat|trash)__' 
--                   UNION ALL
--                   SELECT m.id, m.parent_id, m.file_path, m.user_filename, m.category, m.status
--                     FROM media AS m JOIN myfile AS t ON m.parent_id =t.id 
--                       WHERE m.parent_id !='0' AND m.file_path not REGEXP '^/__(chat|trash)__' 
--                 )
--               SELECT id, parent_id, file_path, user_filename, category, `status` FROM myfile;
--             ELSE 
--               REPLACE INTO _innerfile (id, parent_id, file_path, user_filename, category, `status`) 
--                 SELECT id, parent_id, file_path, user_filename, category, `status` FROM media WHERE id = _nid;
--             END IF;
--           END IF;
--           REPLACE INTO _outerfile (id, parent_id, file_path, user_filename, category, `status`, nid)
--           SELECT id, parent_id, file_path, user_filename, category, `status` ,_nid FROM _innerfile;
--         END IF;
      
--         FETCH dbcursor INTO _nid, _src_db_name, _ftype, _hub_db_name;
--       END WHILE;
--     CLOSE dbcursor;
--   END; 
  
--   SET _finished = 0;
--   BEGIN
--     DECLARE dbhub_cursor CURSOR FOR SELECT 
--       nid, parent_id, db_name FROM _outerfile f LEFT JOIN yp.entity USING(id) 
--         WHERE category IN('hub') AND f.file_path not REGEXP '^/__(chat|trash)__';

--     DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
--     OPEN dbhub_cursor;
--       FETCH dbhub_cursor INTO _nid, _parent_id, _hub_db_name;
--       WHILE NOT _finished DO 
--         IF _hub_db_name IS NOT NULL THEN 
--           SET @_file_count = 0;
--           SET @s = CONCAT(
--             "SELECT IFNULL(SUM(is_new(metadata, owner_id, ?)), 0) FROM ", _hub_db_name ,
--             ".media WHERE file_path not REGEXP '^/__(chat|trash)__' INTO @_file_count"
--           );
--           PREPARE stmt FROM @s;
--           EXECUTE stmt USING _uid;
--           DEALLOCATE PREPARE stmt;

--           SELECT @_file_count  INTO @_new_file;
          
--           SET @s2 = CONCAT(
--             "SELECT IFNULL(SUM(is_new(metadata, author_id, ?)), 0) FROM ", _hub_db_name ,
--             ".channel INTO @_chat_count"
--           );
--           PREPARE stmt2 FROM @s2;
--           EXECUTE stmt2 USING _uid;
--           DEALLOCATE PREPARE stmt2;

--           SELECT @_chat_count + @_new_chat INTO @_new_chat;
--         END IF;
--         FETCH dbhub_cursor INTO _nid, _parent_id, _hub_db_name;
--       END WHILE;
--     CLOSE dbhub_cursor;
--   END; 
--   SELECT IFNULL(GROUP_CONCAT(nid), _hubs) FROM _outerfile WHERE category='hub' INTO @_hubs;
--   SELECT SUM(is_new(m.metadata, owner_id, _uid)) FROM _outerfile INNER JOIN media m USING(id) 
--     INTO @_file_count;
--   -- SELECT COUNT(DISTINCT ii.id) FROM _outerfile ii INNER JOIN media USING(id) 
--   --   WHERE IF(ii.metadata IS NULL OR ii.metadata IN('{}', '') OR owner_id = _uid OR 
--   --     JSON_EXTRACT(ii.metadata, "$._seen_") IS NOT NULL OR
--   --     JSON_EXTRACT(ii.metadata, @_seen_uid) IS NOT NULL, 0, 1) INTO @_file_count;

--   SELECT @_file_count + @_new_file INTO @_new_file;
--   SELECT _node_id nid, _uid `uid`, _hub_id AS hub_id, @_hubs hubs,
--     @_new_chat new_chat, @_new_file AS count, @_new_file new_file,
--     CAST((@_new_chat + @_new_file) as UNSIGNED INTEGER) notify;
  
-- END $



DELIMITER ;

