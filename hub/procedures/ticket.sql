DELIMITER $


DROP PROCEDURE IF EXISTS `mfs_ticket_init`$
CREATE PROCEDURE `mfs_ticket_init`()
BEGIN

 SELECT node_id_from_path('/__ticket__') INTO @temp_chat_id;
 IF @temp_chat_id IS NULL THEN 
    call mfs_make_dir("0", JSON_ARRAY('__ticket__'), 0);
    UPDATE media SET status='hidden' where file_path='/__ticket__.folder';
 END IF;

END$

DROP PROCEDURE IF EXISTS `map_ticket_add`$
CREATE PROCEDURE `map_ticket_add`(
  IN _message_id VARCHAR(16),
  IN _ticket_id  int(11) 
  )
BEGIN
  INSERT INTO map_ticket(message_id,ticket_id)
  SELECT _message_id, _ticket_id;
  UPDATE yp.ticket SET utime = UNIX_TIMESTAMP() WHERE ticket_id =_ticket_id;
  SELECT *  FROM map_ticket WHERE message_id =_message_id;  
END $


DROP PROCEDURE IF EXISTS `ticket_show`$
CREATE PROCEDURE `ticket_show`(
  IN _ticket_id  int(11),
  IN _uid VARCHAR(16),
  IN _page INT(6)  
  )
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;
  DECLARE _hub_id VARCHAR(16);  
    CALL pageToLimits(_page, _offset, _range);


      -- SELECT sys_id FROM  (
      --   SELECT  c.sys_id FROM
      --   yp.ticket t 
      --   INNER JOIN map_ticket mt ON t.ticket_id= mt.ticket_id
      --   INNER JOIN channel c ON mt.message_id = c.message_id
      --   INNER JOIN yp.drumate d  ON c.author_id=d.id
      --   WHERE t.ticket_id = _ticket_id 
      --   ORDER BY  c.sys_id DESC 
      --   LIMIT _offset ,_range ) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id;


    SELECT last_sys_id FROM yp.ticket WHERE ticket_id = _ticket_id  INTO _ref_sys_id;
    SELECT ref_sys_id FROM yp.read_ticket_channel 
    WHERE uid = _uid AND ticket_id = _ticket_id  INTO _old_ref_sys_id;


    IF ( _ref_sys_id > IFNULL(_old_ref_sys_id,0)) THEN  
    
      UPDATE channel c INNER JOIN map_ticket mt ON mt.message_id = c.message_id
      SET  c.metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
      WHERE c.sys_id <= _ref_sys_id   AND mt.ticket_id = _ticket_id AND
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;

      INSERT INTO yp.read_ticket_channel(uid,ticket_id , ref_sys_id,ctime) SELECT _uid,_ticket_id,_ref_sys_id,UNIX_TIMESTAMP() 
      ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();
    END IF; 


    SELECT id FROM yp.entity WHERE db_name= DATABASE() INTO _hub_id; 


    SELECT 
      _page as `page`,
      c.sys_id,
      t.ticket_id,
      c.author_id, 
      'ticket' message_type,   
      c.message,   
      c.message_id, 
      c.thread_id, 
      c.is_forward, 
      c.attachment, 
      CASE WHEN LTRIM(RTRIM(c.attachment))='' OR  c.attachment IS NULL THEN 0 ELSE 1 END is_attachment, 
      _hub_id hub_id,
      c.status,     
      c.ctime,   
      CASE WHEN  t.message_id = c.message_id THEN 1 ELSE 0 END  is_ticket,  
      CASE WHEN  t.message_id = c.message_id THEN t.metadata ELSE NULL END metadata,
      IFNULL(d.firstname, 'Support') firstname, 
      IFNULL(d.lastname, 'Team') lastname, 
      IFNULL(d.fullname, 'Support Team') fullname,
      CASE WHEN _old_ref_sys_id  <  c.sys_id THEN 1 ELSE 0 END is_notify,  
      CASE WHEN JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(c.metadata , '$._seen_')  >=  JSON_LENGTH(c.metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen
    FROM 
      yp.ticket t 
      INNER JOIN map_ticket mt ON t.ticket_id= mt.ticket_id
      INNER JOIN channel c ON mt.message_id = c.message_id
      LEFT JOIN yp.drumate d  ON c.author_id=d.id
      WHERE t.ticket_id = _ticket_id 
      ORDER BY  c.sys_id DESC 
      LIMIT _offset ,_range;


END $

DROP PROCEDURE IF EXISTS `ticket_list`$
CREATE PROCEDURE `ticket_list`(
  IN _uid VARCHAR(16),
  IN _data JSON,
  IN _page INT(6) 
  )
BEGIN
  DECLARE _domain_id INT;
  DECLARE _is_support INT DEFAULT 0 ;
  DECLARE _length INTEGER DEFAULT 0;
  DECLARE _idx INTEGER DEFAULT 0;
  DECLARE _list JSON; 
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _read_cnt INT ;

  DECLARE _ticket_id INT;
  DECLARE _db_name VARCHAR(500);

  DECLARE _search_ticket_id INT;
  
    CALL pageToLimits(_page, _offset, _range);

    SELECT JSON_QUERY(_data, "$.status") INTO _list;
    SELECT JSON_VALUE(_data, "$.search_ticket_id") INTO _search_ticket_id;


    DROP TABLE IF EXISTS __tmp_status;
    CREATE TEMPORARY TABLE __tmp_status(
      `status` varchar(50)    
    ); 

    SELECT  JSON_LENGTH(_list)  INTO _length;

 
    WHILE _idx < _length  DO 
      INSERT INTO __tmp_status SELECT JSON_UNQUOTE(JSON_EXTRACT(_list, CONCAT("$[", _idx, "]")));
      SELECT _idx + 1 INTO _idx;
    END WHILE;


    SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
    SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' AND conf_value =_domain_id INTO _is_support;

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node AS 
    SELECT 
      _page page,
      t.ticket_id,
      sb.db_name db_name,  
      t.ticket_id `message`,  
      t.uid,
      t.metadata,
      t.status,
      (SELECT IF(COUNT(*), 1, 0) FROM yp.socket soc WHERE soc.uid=t.uid ) is_online,
      (SELECT 
          COUNT(1)
        FROM 
          map_ticket mt 
          INNER JOIN channel c ON mt.message_id = c.message_id
          LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid = _uid
          WHERE mt.ticket_id = t.ticket_id  AND c.sys_id > IFNULL(rtc.ref_sys_id,0) ) room_count,
      d.firstname, d.lastname, d.fullname , o.name org_name, t.utime
    FROM 
      yp.ticket t
      INNER JOIN yp.hub h ON h.owner_id = t.uid AND `serial`= 0
      INNER JOIN yp.entity sb ON h.id = sb.id 
      INNER JOIN yp.drumate d  ON t.uid =d.id
      INNER JOIN yp.organisation o ON o.domain_id= d.domain_id
    WHERE   
      t.uid = CASE WHEN  _is_support = 1 THEN t.uid ELSE _uid END   AND 
      t.status IN (SELECT status FROM __tmp_status ) AND 
      t.ticket_id = IFNULL(_search_ticket_id,t.ticket_id)

      ORDER BY t.ticket_id DESC 
      LIMIT _offset ,_range;

    ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;
    UPDATE _show_node SET is_checked = 1 WHERE db_name IS NULL;

    IF  _is_support = 1 THEN 
      SELECT ticket_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _ticket_id, _db_name; 
      WHILE _ticket_id IS NOT NULL DO
        UPDATE _show_node SET is_checked = 1 WHERE ticket_id = _ticket_id ; 
          SET @st = CONCAT('SELECT 
            COUNT(1)
            FROM ', _db_name ,'.map_ticket mt 
            INNER JOIN ', _db_name ,'.channel c ON mt.message_id = c.message_id
            LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid = ?
            WHERE mt.ticket_id = ? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)
            INTO @read_cnt');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _uid , _ticket_id;
          DEALLOCATE PREPARE stamt; 

        UPDATE _show_node SET is_checked = 1 ,room_count =  @read_cnt WHERE  ticket_id = _ticket_id ; 
        SELECT NULL , NULL  INTO @read_cnt,_ticket_id;
        SELECT ticket_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _ticket_id, _db_name; 
      END WHILE;
    END IF;

    SELECT * FROM _show_node  ORDER BY ticket_id DESC ;

END $


DROP PROCEDURE IF EXISTS `ticket_unreaded`$
CREATE PROCEDURE `ticket_unreaded`(
  IN _uid VARCHAR(16)  CHARACTER SET ascii
)
BEGIN
  DECLARE _type VARCHAR(16);
  DECLARE _sys_id int(11);
  DECLARE _domain_id INT;
  DECLARE _is_support INT DEFAULT 0 ;


  SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
  SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' AND conf_value =_domain_id INTO _is_support;

  SELECT
     c.message_id, t.ticket_id
  FROM 
      yp.ticket t 
  LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
  INNER JOIN  channel c  ON t.last_sys_id  = c.sys_id
 WHERE 
      t.last_sys_id > IFNULL(rtc.ref_sys_id,0) 
      AND CASE WHEN _is_support = 1 THEN t.uid ELSE _uid END = t.uid;
END $



DELIMITER ;

