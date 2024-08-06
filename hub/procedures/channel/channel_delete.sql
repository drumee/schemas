DELIMITER $

DROP PROCEDURE IF EXISTS `channel_delete_hub_me`$
CREATE PROCEDURE `channel_delete_hub_me`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _idx_node INT(4) DEFAULT 0;
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ref_sys_id BIGINT default 0;
  DECLARE _cnt INT ;
  DECLARE _memeber_cnt INT ;
  DECLARE _attachment  JSON;
  DECLARE _node json;
  DECLARE _delete_attachment  JSON;
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0; 
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _max_sys_id BIGINT;
  DECLARE _max_ref_sys_id BIGINT;
 
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;
   DROP TABLE IF EXISTS _show_node;
   CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
   ALTER TABLE _show_node ADD `delete_attachment` JSON;

  SELECT count(id)
  FROM permission p 
  INNER JOIN yp.drumate d ON  p.entity_id=d.id 
  WHERE p.resource_id='*' INTO _memeber_cnt;

  WHILE _idx_node < JSON_LENGTH(_messages) DO 
    SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
    SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;

     
    INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
    SELECT _uid ,_ref_sys_id,UNIX_TIMESTAMP() ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP(); 
    SELECT 0 INTO _cnt;

    SELECT COUNT(1) FROM delete_channel WHERE ref_sys_id = _ref_sys_id INTO _cnt;
    DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= _memeber_cnt ; 
    DELETE FROM channel WHERE message_id = _message_id AND  _cnt= _memeber_cnt; 

    IF _cnt = _memeber_cnt THEN 

      WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
        SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
        SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
        SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
        SELECT _idx_attachment + 1 INTO _idx_attachment;
        UPDATE yp.disk_usage SET size = IFNULL(size,0) - (SELECT IFNULL(SUM(filesize),0) FROM  
        media  WHERE id  =_nid ) WHERE hub_id =_hub_id;

        DELETE FROM  media WHERE id = _nid;
      END WHILE;

     UPDATE _show_node SET delete_attachment = _attachment WHERE message_id = _message_id; 

    END IF;

    SELECT _idx_node + 1 INTO _idx_node;
  END WHILE;


  
    DROP TABLE IF EXISTS `_last_node`;
    CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

    SELECT NULL INTO _ref_sys_id; 
    SELECT 0 INTO _read_cnt;
    SELECT NULL INTO _read_sys_id;


    SELECT  sys_id FROM  (SELECT sys_id  FROM channel c 
    WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id) 
    ORDER BY c.sys_id  DESC ) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id; 



    INSERT INTO _last_node
    SELECT _uid, _hub_id, LEFT(message, 100)  , attachment ,_read_cnt, ctime 
    FROM channel  WHERE sys_id = _ref_sys_id ;

    INSERT INTO _last_node
    SELECT _uid, _hub_id, NULL , NULL ,_read_cnt , NULL  WHERE  _ref_sys_id IS NULL;

   
    SELECT * FROM _show_node;
    SELECT * FROM _last_node;


END$


DROP PROCEDURE IF EXISTS `channel_delete_hub_all`$
CREATE PROCEDURE `channel_delete_hub_all`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN

  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _memeber_cnt INT ;

  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ref_sys_id BIGINT default 0;
  DECLARE _attachment  JSON;
  DECLARE _idx_node INT(4) DEFAULT 0;
  DECLARE _cnt INT ;
  DECLARE _idx_attachment INT(4) DEFAULT 0;
  DECLARE _node json;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _max_sys_id BIGINT;
  DECLARE _max_ref_sys_id BIGINT;
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0;

  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;
  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
  ALTER TABLE _show_node ADD `delete_attachment` JSON;
  
  DROP TABLE IF EXISTS _list_uid;
  CREATE TEMPORARY TABLE _list_uid (
    id VARCHAR(16) CHARACTER SET ascii , 
    hub_id VARCHAR(16) CHARACTER SET ascii,
    `is_checked` boolean default 0 
  );

  INSERT INTO _list_uid (id) 
  SELECT  d.id
  FROM permission p 
  INNER JOIN yp.drumate d ON  p.entity_id=d.id 
  WHERE p.resource_id='*' ;

  SELECT count(id)
  FROM _list_uid p 
  INTO _memeber_cnt;

  WHILE _idx_node < JSON_LENGTH(_messages) DO 
    SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
    SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;
   
    INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
    SELECT id ,_ref_sys_id,UNIX_TIMESTAMP()  FROM _list_uid  ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP();
    SELECT 0 INTO _cnt;

    SELECT COUNT(1) FROM delete_channel WHERE ref_sys_id = _ref_sys_id INTO _cnt;
    DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= _memeber_cnt ; 
    DELETE FROM channel WHERE message_id = _message_id AND  _cnt= _memeber_cnt; 


    IF _cnt = _memeber_cnt THEN 

      WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
        SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
        SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
        SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
        SELECT _idx_attachment + 1 INTO _idx_attachment;

        UPDATE yp.disk_usage SET size = IFNULL(size,0) - 
        (SELECT IFNULL(SUM(filesize),0) FROM  media  WHERE id  =_nid ) 
        WHERE hub_id =_hub_id;
        DELETE FROM  media WHERE id = _nid;
      END WHILE;

      UPDATE _show_node SET delete_attachment = _attachment WHERE message_id = _message_id; 

    END IF;

    SELECT _idx_node + 1 INTO _idx_node;
  END WHILE;

  DROP TABLE IF EXISTS `_last_node`;
  CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

  SELECT  max(sys_id)  FROM  channel c  INTO _max_sys_id; 


  SELECT id  FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id;

    WHILE _drumate_id IS NOT NULL DO

      SELECT NULL INTO _ref_sys_id; 
      SELECT 0 INTO _read_cnt;
      SELECT 0 INTO _read_sys_id;

      SELECT  sys_id FROM  (SELECT sys_id  FROM channel c 
      WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_drumate_id AND ref_sys_id = c.sys_id) 
      ORDER BY c.sys_id  DESC ) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id;

      SELECT  ref_sys_id FROM read_channel WHERE uid = _drumate_id INTO _read_sys_id; 
      SELECT 
         COUNT(sys_id)
      FROM 
      channel c  WHERE  c.sys_id > _read_sys_id INTO _read_cnt ;

      INSERT INTO _last_node
      SELECT _drumate_id, _hub_id, LEFT(message, 100)  , attachment ,_read_cnt, ctime 
      FROM channel  WHERE sys_id = _ref_sys_id ;

      INSERT INTO _last_node
      SELECT _drumate_id, _hub_id, NULL , NULL ,_read_cnt , NULL  WHERE  _ref_sys_id IS NULL;


      UPDATE _list_uid SET is_checked = 1 WHERE id = _drumate_id ;
      SELECT NULL INTO _drumate_id;
      SELECT id  FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id;
    END WHILE;

  SELECT * FROM _show_node;
  SELECT * FROM _last_node;

END$


DELIMITER ;

