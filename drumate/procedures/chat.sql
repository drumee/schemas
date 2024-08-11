DELIMITER $
DROP PROCEDURE IF EXISTS `set_read_message`$
DROP PROCEDURE IF EXISTS `get_rooms`$
DROP PROCEDURE IF EXISTS `send_contact_message`$
DROP PROCEDURE IF EXISTS `send_group_message`$
DROP PROCEDURE IF EXISTS `send_group_file`$
DROP PROCEDURE IF EXISTS `send_contact_file`$
DROP PROCEDURE IF EXISTS `get_entity_name`$
DROP PROCEDURE IF EXISTS `mfs_attachment_detail`$

------  attachment  media handling Start





DROP PROCEDURE IF EXISTS `mfs_push_chatfile`$
-- CREATE PROCEDURE `mfs_push_chatfile`(
--   IN _author_id VARCHAR(16),
--   IN _nodes     JSON,
--   IN _entities  JSON
-- )
-- BEGIN
--   DECLARE _out JSON ;
--   DECLARE _mfs_copy JSON;
--   DECLARE _new_attachment JSON;
--   DECLARE _new_nodes JSON;
--   DECLARE _this_new_attachment JSON;


--   DECLARE _attachment JSON;

--   DECLARE _entity_id VARCHAR(16);
--   DECLARE _entity_db VARCHAR(255);
--   DECLARE _entity_type  VARCHAR(512);

--   DECLARE _hub_id VARCHAR(16);
--   DECLARE _hub_db VARCHAR(255);
  


--   DECLARE _this_hub_id VARCHAR(16);
--   DECLARE _this_hub_db VARCHAR(255);

--   DECLARE _message_id VARCHAR(16);
--   DECLARE _forward_message_id VARCHAR(16);
--   DECLARE _thread_id VARCHAR(16);

--   DECLARE _message VARCHAR(6000);

--   DECLARE _node JSON;

--   DECLARE _idx_node INT(4) DEFAULT 0; 
--   DECLARE _idx_entity INT(4) DEFAULT 0;
--   DECLARE _idx_attachment INT(4) DEFAULT 0; 
  
--   DECLARE _nid VARCHAR(16);
--   DECLARE _new_id json;

--   DECLARE _mfs_detail JSON;
--   DECLARE _temp_result JSON;
--   DECLARE _hub_dir VARCHAR(512);
--   DECLARE _entity_dir VARCHAR(512);
--   DECLARE _this_hub_dir VARCHAR(512);

  
--   SELECT '[]' INTO _out ;
--   SELECT '[]' INTO _mfs_copy ;
--   SELECT '[]' INTO _new_attachment ;
--   SELECT '[]' INTO _new_nodes ;
--   SELECT '[]' INTO _this_new_attachment ;
  


-- --  First : Entity loop 
--     WHILE _idx_entity < JSON_LENGTH(_entities) DO 
      
--       SELECT get_json_array(_entities, _idx_entity) INTO _entity_id;
     
--       SELECT db_name,home_dir, type FROM yp.entity WHERE id=_entity_id INTO _entity_db,_entity_dir, _entity_type ;
      
--         SELECT 0 INTO _idx_node;
-- --  SECOND  : NODE  loop 
--         WHILE _idx_node < JSON_LENGTH(_nodes) DO 
        
         

--           SELECT JSON_QUERY(_nodes, CONCAT("$[", _idx_node, "]") ) INTO _node;
                
--           SELECT JSON_VALUE(_node, '$.message_id') INTO _message_id;
--           SELECT JSON_VALUE(_node, '$.message') INTO _message;
--           SELECT JSON_QUERY(_node, '$.attachment') INTO _attachment;
--           SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
--           SELECT JSON_VALUE(_node, '$.forward_message_id') INTO _forward_message_id;
--           SELECT JSON_VALUE(_node, '$.thread_id') INTO _thread_id;


          
--           SELECT db_name,home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db,_hub_dir ;
--           SELECT db_name,home_dir,id FROM yp.entity WHERE db_name=DATABASE() INTO  _this_hub_db ,_this_hub_dir, _this_hub_id ;


--           SELECT 0 INTO _idx_attachment;
         
-- --  THIRD  : attachment loop     
--             WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
  
--                 SELECT get_json_array(_attachment, _idx_attachment) INTO _nid;
  
--                 SET @st = CONCAT('CALL ', _hub_db ,'.mfs_fetch(?,?)');
--                 PREPARE stamt FROM @st;
--                 EXECUTE stamt USING JSON_OBJECT('nid',_nid),_mfs_detail  ;
--                 DEALLOCATE PREPARE stamt; 

--                 SET @st = CONCAT('CALL ', _entity_db ,'.mfs_post_chatfile(?,?)');
--                 PREPARE stamt FROM @st;
--                 EXECUTE stamt USING JSON_MERGE(_mfs_detail, JSON_OBJECT('message_id',_message_id),JSON_OBJECT('author_id',_author_id)),_new_id;
--                 DEALLOCATE PREPARE stamt;

--                SELECT NULL INTO _temp_result ;
--                SELECT 
--                JSON_MERGE ( 
--                 JSON_OBJECT( 'srclst',   JSON_MERGE( JSON_OBJECT('nid', _nid),  JSON_OBJECT('mfs_root',CONCAT (_hub_dir  , "/__storage__/"  )))),
--                 JSON_OBJECT( 'desclst',   JSON_MERGE( JSON_OBJECT('nid', _new_id),  JSON_OBJECT('mfs_root',CONCAT( _entity_dir  ,"/__storage__/"))))
--                ) INTO _temp_result;
              
--                SELECT JSON_ARRAY_INSERT(_mfs_copy , '$[0]', _temp_result ) INTO _mfs_copy;
--                SELECT JSON_ARRAY_INSERT(_new_attachment , '$[0]', _new_id ) INTO _new_attachment;



--               IF _this_hub_id <> _hub_id THEN 
--                   SET @st = CONCAT('CALL ', _this_hub_db ,'.mfs_post_chatfile(?,?)');
--                   PREPARE stamt FROM @st;
--                   EXECUTE stamt USING JSON_MERGE(_mfs_detail, JSON_OBJECT('message_id',_message_id),JSON_OBJECT('author_id',_author_id)),_new_id;
--                   DEALLOCATE PREPARE stamt;
              
--                   SELECT NULL INTO _temp_result ;
--                   SELECT 
--                     JSON_MERGE ( 
--                       JSON_OBJECT( 'srclst',   JSON_MERGE( JSON_OBJECT('nid', _nid),  JSON_OBJECT('mfs_root',CONCAT (_hub_dir  , "/__storage__/"  )))),
--                       JSON_OBJECT( 'desclst',   JSON_MERGE( JSON_OBJECT('nid', _new_id),  JSON_OBJECT('mfs_root',CONCAT( _this_hub_dir  ,"/__storage__/"))))
--                     ) INTO _temp_result;
                    
--                   SELECT JSON_ARRAY_INSERT(_mfs_copy , '$[0]', _temp_result ) INTO _mfs_copy;
--                   SELECT JSON_ARRAY_INSERT(_this_new_attachment , '$[0]', _new_id ) INTO _this_new_attachment;
             
--               END IF ; 


--                SELECT _idx_attachment + 1 INTO _idx_attachment;
--             END WHILE;
-- --  THIRD END : attachment loop   
--           SELECT NULL INTO _temp_result ;
--           SELECT 
--           JSON_MERGE ( 
--                 JSON_OBJECT( 'author_id',_author_id ),
--                 JSON_OBJECT( 'message_id',_message_id ),
--                 JSON_OBJECT( 'entity_id',_entity_id ),
--                 JSON_OBJECT( 'entity_type',_entity_type )
                
                
--           ) INTO _temp_result;
--           SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'forward_message_id', _forward_message_id ) , JSON_OBJECT( 'hub_id', _hub_id)) INTO _temp_result WHERE _forward_message_id IS NOT NULL;
--           SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'thread_id', _thread_id )) INTO _temp_result WHERE _thread_id IS NOT NULL;

--            SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'message', _message )) INTO _temp_result WHERE _message IS NOT NULL;
--            SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'postattachment', _new_attachment ), JSON_OBJECT( 'attachment', _attachment )) INTO _temp_result WHERE _new_attachment <> '[]';
--            SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'preattachment', _this_new_attachment )) INTO _temp_result WHERE _this_new_attachment <> '[]';


--           SELECT JSON_ARRAY_INSERT(_new_nodes , '$[0]', _temp_result ) INTO _new_nodes;
--           SELECT '[]' INTO _new_attachment ;
--           SELECT '[]' INTO _this_new_attachment ;
--           SELECT _idx_node + 1 INTO _idx_node;
--         END WHILE;
-- --  SECOND END  : NODE  loop 
--       SELECT _idx_entity + 1 INTO _idx_entity;
      
--     END WHILE;
-- -- First END: Entity loop 
--  SELECT _mfs_copy mfs, JSON_UNQUOTE(_new_nodes) new_nodes ;
-- END $

------  attachment  media handling END


/*
PURPOSE      : To place a  channel entry in sender hub   and  receiver hub 
NAME         : send_chat_message
INPUT FORMAT :  
{
"message_id" : "xxxx", "author_id": "xxxx","entity_id": "xxxx", "message": "xxx", "attachment": ["xxxx","xxx"],"postattachment": ["xx","xxx"],
"forward_message_id":"xxxx" , thread_id:'xxx'
}
OUTPUT FORMAT: 
{
"message_id" : "xxxx", "author_id": "xxxx","entity_id": "xxxx", "message": "xxx", "attachment": ["xxxx","xxx"],"postattachment": ["xx","xxx"],
"forward_message_id":"xxxx" , thread_id:'xxx'
}

SAMPLE : 
CALL send_chat_message ('{
"message_id" : "test1", 
"author_id": "46fb4fc946fb4fce",
"entity_id": "197e7e69197e7e72",
"message": "FROM GOPI",
"attachment": ["9d7929e19d7929f9","53cec36653cec372"],
"postattachment": ["pd7929e19d7929f9","p3cec36653cec372"]
}');

*/
DROP PROCEDURE IF EXISTS `send_chat_message`$
-- CREATE PROCEDURE `send_chat_message`(
--  IN _in JSON
-- )
-- BEGIN
--  DECLARE _entity JSON;
--  DECLARE _out JSON;
--  DECLARE _temp_out TEXT;

--  DECLARE _author_id VARCHAR(16);
--  DECLARE _entity_id VARCHAR(16);
--  DECLARE _message  TEXT;

--  DECLARE _thread_id  VARCHAR(16);
--  DECLARE _forward_message_id VARCHAR(16);
--  DECLARE _attachment JSON;
--  DECLARE _preattachment JSON;

--  DECLARE _entity_db VARCHAR(255); 
--  DECLARE _message_id VARCHAR(16);
--  DECLARE _ctime int(11) unsigned;

--  DECLARE _ref_sys_id int(11) unsigned;
--  DECLARE _temp_result JSON;

--   SELECT JSON_VALUE(_in, "$.author_id") INTO _author_id;
--   SELECT JSON_VALUE(_in, "$.entity_id") INTO _entity_id;
--   SELECT JSON_VALUE(_in, "$.message") INTO _message; 
--   SELECT JSON_VALUE(_in, "$.thread_id") INTO _thread_id; 
--   SELECT JSON_VALUE(_in, "$.forward_message_id") INTO _forward_message_id; 
--   SELECT JSON_QUERY(_in, "$.attachment") INTO _attachment; 
--   SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id;
--   SELECT JSON_VALUE(_in, "$.preattachment") INTO _preattachment; 
  
--   SELECT UNIX_TIMESTAMP() INTO _ctime; 
--   -- SELECT  yp.uniqueId() INTO _message_id;
--   SELECT db_name FROM yp.entity WHERE id=_entity_id INTO _entity_db;

--   INSERT INTO channel (message_id,author_id,entity_id,message,thread_id,ctime,attachment)
--   SELECT _message_id,_author_id,_entity_id,_message,_thread_id,_ctime,IFNULL(_preattachment,_attachment) ;

--   UPDATE channel SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('_delivered_',   JSON_OBJECT(_entity_id,_ctime)))
--   WHERE message_id=_message_id;

--   UPDATE channel SET metadata=JSON_MERGE(IFNULL(metadata, '{}'),   JSON_OBJECT('_seen_', JSON_OBJECT(_author_id, 1)), JSON_OBJECT('_delivered_',   JSON_OBJECT(_author_id,_ctime)))
--   WHERE message_id=_message_id;

--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'surname', surname)) FROM contact WHERE uid = _entity_id  AND surname IS NOT NULL INTO _entity;
--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'firstname', firstname)) FROM contact WHERE uid = _entity_id  AND firstname IS NOT NULL INTO _entity;
--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'lastname', lastname)) FROM contact WHERE uid = _entity_id  AND lastname IS NOT NULL INTO _entity;
--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'contact_id', id)) FROM contact WHERE uid = _entity_id   INTO _entity;
--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'id', uid)) FROM contact WHERE uid = _entity_id AND uid IS NOT NULL  INTO _entity;

--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'firstname', firstname)) FROM yp.drumate WHERE id = _entity_id AND  _entity = '{}' INTO _entity;
--   SELECT JSON_MERGE ( IFNULL(_entity,'{}'), JSON_OBJECT( 'lastname', lastname)) FROM yp.drumate WHERE id = _entity_id  AND  _entity = '{}' INTO _entity;

--    UPDATE channel SET 
--     is_forward =1, 
--     metadata=JSON_MERGE(
--                         IFNULL(metadata, '{}'), 
--                         JSON_OBJECT('forward_message_id',   _forward_message_id),
--                         JSON_OBJECT('forward_hub_id',   JSON_UNQUOTE(JSON_EXTRACT(_in, "$.hub_id")))
--                        )
--   WHERE message_id=_message_id AND _forward_message_id is NOT NULL; 

--   SELECT sys_id FROM channel WHERE message_id = _message_id   INTO _ref_sys_id;

 
--   INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
--   SELECT _entity_id, _ref_sys_id,_message, _ctime ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id, ctime =_ctime ,message=_message;

--   SELECT  JSON_MERGE(_in,  JSON_OBJECT('ctime',_ctime )) INTO _in;
  
  
 
  

--   SET @st = CONCAT('CALL ', _entity_db ,'.post_chat_message(?,?)');
--   PREPARE stamt FROM @st;
--   EXECUTE stamt USING _in , _out;
--   DEALLOCATE PREPARE stamt; 

--   CALL acknowledge_message( JSON_MERGE( JSON_OBJECT('message_id',_message_id ) , JSON_OBJECT('entity_id',_entity_id ) ,JSON_OBJECT('uid',_author_id ))  );
--   CALL count_yet_read (JSON_OBJECT('entity_id',_entity_id ),  _temp_result );
--   SELECT JSON_MERGE(_temp_result,  _in ) INTO _in;
--   SELECT JSON_MERGE(_in, JSON_OBJECT('to_id',_author_id )) INTO _in;
--   SELECT JSON_MERGE(_in, JSON_OBJECT('entity',_entity )) WHERE _entity != '{}' INTO _in;
     
--   IF _forward_message_id IS NOT NULL THEN 
--      SELECT  JSON_MERGE(_in,  JSON_OBJECT('is_forward',1 )) INTO _in;
--      SELECT  JSON_MERGE(_out,  JSON_OBJECT('is_forward',1 )) INTO _out;
--   ELSE 
--     SELECT  JSON_MERGE(_in,  JSON_OBJECT('is_forward',0 )) INTO _in;
--     SELECT  JSON_MERGE(_out,  JSON_OBJECT('is_forward',0 )) INTO _out;
--   END IF ; 


--   SELECT _in  myresult, _out hisresult;


-- END$    


/*
PURPOSE      : To place a  channel entry in receiver hub 
NAME         : send_chat_message
INPUT FORMAT :  
{
"message_id" : "xxxx", "author_id": "xxxx","entity_id": "xxxx", "message": "xxx", "attachment": ["xxxx","xxx"],"postattachment": ["xx","xxx"],
"forward_message_id":"xxxx" , thread_id:'xxx'
}
OUTPUT FORMAT: 
{
"message_id" : "xxxx", "author_id": "xxxx","entity_id": "xxxx", "message": "xxx", "attachment": ["xxxx","xxx"],"postattachment": ["xx","xxx"],
"forward_message_id":"xxxx" , thread_id:'xxx'
}

*/


DROP PROCEDURE IF EXISTS `post_chat_message`$
-- CREATE PROCEDURE `post_chat_message`(
-- IN _in JSON,
-- OUT _out JSON
-- )
-- BEGIN
--  DECLARE _author JSON;
--  DECLARE _author_id VARCHAR(16);
--  DECLARE _entity_id VARCHAR(16);
--  DECLARE _message  TEXT;

--  DECLARE _thread_id  VARCHAR(16);
--  DECLARE _forward_message_id VARCHAR(16);
--  DECLARE _attachment JSON;

--  DECLARE _entity_db VARCHAR(255); 
--  DECLARE _message_id VARCHAR(16);
--  DECLARE _ctime int(11) unsigned;

--  DECLARE _ref_sys_id int(11) unsigned;
--  DECLARE _temp_result JSON;


--   SELECT JSON_VALUE(_in, "$.author_id") INTO _author_id;
--   SELECT JSON_VALUE(_in, "$.entity_id") INTO _entity_id;
--   SELECT JSON_VALUE(_in, "$.message") INTO _message; 
--   SELECT JSON_VALUE(_in, "$.thread_id") INTO _thread_id; 
--   SELECT JSON_VALUE(_in, "$.forward_message_id") INTO _forward_message_id; 
--   SELECT JSON_VALUE(_in, "$.postattachment") INTO _attachment;
--   SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id; 
--   SELECT JSON_VALUE(_in, "$.ctime") INTO _ctime;


--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'surname', surname)) FROM contact WHERE uid = _author_id  AND surname IS NOT NULL INTO _author;
--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'firstname', firstname)) FROM contact WHERE uid = _author_id  AND firstname IS NOT NULL INTO _author;
--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'lastname', lastname)) FROM contact WHERE uid = _author_id  AND lastname IS NOT NULL INTO _author;
--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'contact_id', id)) FROM contact WHERE uid = _author_id   INTO _author;
--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'id', uid)) FROM contact WHERE uid = _author_id AND uid IS NOT NULL  INTO _author;

--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'firstname', firstname)) FROM yp.drumate WHERE id = _author_id AND  _author = '{}' INTO _author;
--   SELECT JSON_MERGE ( IFNULL(_author,'{}'), JSON_OBJECT( 'lastname', lastname)) FROM yp.drumate WHERE id = _author_id  AND  _author = '{}' INTO _author;

--   INSERT INTO channel (message_id,author_id,entity_id,message,thread_id,ctime,attachment)
--   SELECT _message_id,_author_id,_author_id,_message,_thread_id,_ctime,_attachment ;


--   UPDATE channel SET 
--     is_forward =1, 
--     metadata=JSON_MERGE(
--                         IFNULL(metadata, '{}'), 
--                         JSON_OBJECT('forward_message_id',   _forward_message_id),
--                         JSON_OBJECT('forward_hub_id',   JSON_UNQUOTE(JSON_EXTRACT(_in, "$.hub_id")))
--                        )
--   WHERE message_id=_message_id AND _forward_message_id is NOT NULL; 

--   SELECT sys_id FROM channel WHERE message_id = _message_id   INTO _ref_sys_id;

--   INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
--   SELECT _author_id, _ref_sys_id,_message, _ctime ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id, ctime =_ctime ,message=_message;
--   SELECT  JSON_MERGE(_in,  JSON_OBJECT('author',_author )) INTO _out;


--   CALL count_yet_read (JSON_OBJECT('entity_id',_author_id ), _temp_result);
--   SELECT JSON_MERGE(_temp_result,  _out ) INTO _out;
--   SELECT JSON_REMOVE(_out,"$.entity_id" ) INTO _out;
--   SELECT JSON_MERGE(_out, JSON_OBJECT('entity_id',_author_id ) ,JSON_OBJECT('to_id',_entity_id )   )  INTO _out;
--   SELECT JSON_MERGE(_out, JSON_OBJECT('entity',_author )) WHERE _author != '{}' INTO _out;

-- END$  














-- =========================================================
--
-- =========================================================
-- DROP PROCEDURE IF EXISTS `contact_chat_rooms`$
-- CREATE PROCEDURE `contact_chat_rooms`(
--   IN _key VARCHAR(500), 
--   IN _tag_id  VARCHAR(16), 
--   IN _page INT(6)
-- )
-- BEGIN
--   DECLARE _range bigint;
--   DECLARE _offset bigint;
--     DECLARE _lvl INT(4);
--     CALL pageToLimits(_page, _offset, _range); 

--    IF _key IN ('', '0') THEN 
--     SELECT NULL INTO  _key;
--    END IF;

--     DROP TABLE IF EXISTS _tag;
--       CREATE TEMPORARY TABLE _tag(
--         `tag_id` varchar(16) NOT NULL,
--         `is_checked` boolean default 0
--       );

--     DROP TABLE IF EXISTS _map_tag;
--       CREATE TEMPORARY TABLE _map_tag(
--         `tag_id` varchar(16) NOT NULL,
--         `id`     varchar(16) NOT NULL
--       );

   
--     IF _tag_id IS  NULL OR (ltrim(_tag_id) = '') THEN
--         INSERT INTO _tag (tag_id) SELECT tag_id from  tag ; 
--     ELSE 
      
--       INSERT INTO _tag (tag_id) SELECT _tag_id;
--       WHILE (IFNULL((SELECT 1 FROM _tag  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
--         SELECT tag_id  FROM _tag WHERE is_checked = 0 LIMIT 1  INTO _tag_id;
--         INSERT INTO _tag (tag_id) SELECT tag_id FROM tag WHERE  parent_tag_id = _tag_id;
--         UPDATE _tag SET is_checked =  1 WHERE tag_id =_tag_id; 
--         SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
--       END WHILE; 
--     END IF;


--     INSERT INTO _map_tag (tag_id,id) SELECT tag_id ,id FROM  map_tag WHERE tag_id in (SELECT tag_id FROM _tag); 


--     SELECT 
--       _page as `page`, 
--       c.id contact_id, 
--       c.uid id,
--       IFNULL(c.firstname, d.firstname) firstname,
--       IFNULL(c.lastname, d.lastname) lastname,
--       tc.message,
--       tc.ctime, 
--       IFNULL(c.surname, IFNULL(c.firstname, d.firstname)) surname,
--       IF(socket.uid IS NULL, 0, 1) `online`,
--       IFNULL(( 
--         SELECT 
--           COUNT(1)
--         FROM 
--           channel ch 
--         INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
--         WHERE
--           ch.entity_id = ch.author_id AND 
--           rc.entity_id <> rc.uid  AND 
--           ch.sys_id > rc.ref_sys_id AND 
--           ch.entity_id = c.uid), 0) room_count 
--     FROM
--       contact c
--       INNER JOIN yp.entity e ON e.id = c.uid
--       INNER JOIN yp.drumate d ON d.id = c.entity
--       LEFT JOIN time_channel tc ON tc.entity_id = c.uid
--       LEFT JOIN yp.socket ON socket.uid = c.uid
--     WHERE 
--      CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  c.id IN ( SELECT id FROM _map_tag) ELSE c.id =c.id END 
--      AND c.status <> 'received' 
--      AND 
--         (c.firstname LIKE CONCAT(TRIM(IFNULL(_key,c.firstname)), '%') OR 
--         c.lastname LIKE CONCAT(TRIM(IFNULL(_key, c.lastname)), '%') OR 
--         c.surname LIKE CONCAT(TRIM(IFNULL(_key,c.surname)), '%') OR 
--         c.entity LIKE CONCAT(TRIM(IFNULL(_key, c.entity)), '%') )
--     ORDER BY 
--       IFNULL(tc.ctime,0) DESC,  c.uid  ASC
--       LIMIT _offset, _range;

-- END$


-- DROP PROCEDURE IF EXISTS `group_chat_rooms`$
-- CREATE PROCEDURE `group_chat_rooms`(
--   IN _key VARCHAR(500), 
--   IN _page INT(6)
-- )
-- BEGIN


-- DECLARE _range bigint;
-- DECLARE _offset bigint;
-- DECLARE _finished  INTEGER DEFAULT 0; 
-- DECLARE _db_name VARCHAR(500);
-- DECLARE _temp_result JSON;
-- DECLARE _uid VARCHAR(16);
-- DECLARE _nid VARCHAR(16);
-- DECLARE _read_cnt INT ;

-- DECLARE _attachment  VARCHAR(6000) ;
-- DECLARE _ctime INT(11) unsigned;
-- DECLARE _message mediumtext;
-- DECLARE _temp_nid VARCHAR(16);

--   IF _key IN ('', '0') THEN 
--     SELECT NULL INTO  _key;
--   END IF;


-- CALL pageToLimits(_page, _offset, _range); 


-- SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
--  DROP TABLE IF EXISTS _show_node;
--  CREATE TEMPORARY TABLE _show_node  AS  
--     SELECT 
--       m.id ,  
--       IFNULL(h.name, user_filename)  group_name, 
--       0 room_count,
--       db_name    
--     FROM 
--     media m
--     INNER JOIN yp.hub h on  h.id = m.id 
--     INNER  JOIN yp.entity he ON m.id = he.id
--     WHERE category = 'hub'
--     AND ( IFNULL(h.name, user_filename) LIKE CONCAT(TRIM(IFNULL(_key,IFNULL(h.name, user_filename) )), '%') ); -- AND db_name = '5_871bff3e871bff43'
   
--     ALTER TABLE _show_node ADD message mediumtext;
--     ALTER TABLE _show_node ADD ctime INT(11) unsigned;
--     ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;


--     SELECT id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
--     WHILE _nid IS NOT NULL DO
 
--           SET @st = CONCAT('CALL ', _db_name ,'.room_detail(?,?)');
--           PREPARE stamt FROM @st;
--           EXECUTE stamt USING  JSON_OBJECT('uid',_uid ) , _temp_result ;
--           DEALLOCATE PREPARE stamt; 
        
--           SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.read_cnt")) INTO _read_cnt;  
--           SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.message")) INTO _message;  
--           SELECT JSON_UNQUOTE(JSON_EXTRACT(_temp_result, "$.ctime")) INTO _ctime;  
--           UPDATE _show_node SET  
--             room_count =  _read_cnt,
--             `message` =  _message,  
--             ctime =  _ctime  
--           WHERE id = _nid ;

--         UPDATE _show_node SET is_checked = 1 WHERE id = _nid ;
--         SELECT NULL , NULL ,NULL,NULL INTO _read_cnt,_message,_ctime ,_nid;
--         SELECT id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
--      END WHILE;



--     SELECT  _page as `page`, id,group_name,room_count,message,ctime  FROM  _show_node  
--     ORDER BY IFNULL(ctime,0) DESC, id ASC 
--     LIMIT _offset, _range;
     
-- END$







DROP PROCEDURE IF EXISTS `channel_delete`$
-- CREATE PROCEDURE `channel_delete`(
--   IN _option VARCHAR(16),
--   IN _messages JSON
-- )
-- BEGIN

--   DECLARE _ref_sys_id int(11) unsigned default 0 ;
--   DECLARE _sys_id int(11) unsigned default 0 ;
--   DECLARE _message_id VARCHAR(16);
--   DECLARE _idx_node INT(4) DEFAULT 0; 

--   DECLARE _ctime INT(11) unsigned;
--   DECLARE _entity_id VARCHAR(16);
--   DECLARE _entity_db VARCHAR(255);
--   SELECT UNIX_TIMESTAMP() INTO _ctime;
  
--   DROP TABLE IF EXISTS _show_node;
--   CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;

--   WHILE _idx_node < JSON_LENGTH(_messages) DO 
      
--     SELECT get_json_array(_messages, _idx_node) INTO _message_id;
  
--     INSERT INTO _show_node SELECT  * FROM channel WHERE message_id = _message_id;
 
    
--     IF _option='all' THEN
--       SELECT entity_id FROM channel WHERE message_id = _message_id INTO _entity_id; 
--       SELECT db_name FROM yp.entity WHERE id = _entity_id INTO _entity_db; 

--       SET @st = CONCAT('DELETE FROM ', _entity_db ,'.channel WHERE message_id= ?');
--       PREPARE stamt FROM @st;
--       EXECUTE stamt USING _message_id ;
--       DEALLOCATE PREPARE stamt; 
--     END IF; 
    
--     DELETE FROM channel WHERE message_id = _message_id; 
    
--     SELECT NULL, NULL, NULL INTO _message_id,_entity_id,_entity_db ;
--     SELECT _idx_node + 1 INTO _idx_node;
--   END WHILE;
 

--   SELECT * FROM _show_node;

-- END$

