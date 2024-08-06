
DELIMITER $


DROP PROCEDURE IF EXISTS `channel_list_messages`$
CREATE PROCEDURE `channel_list_messages`(
  IN _uid VARCHAR(16),
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _recipient_db VARCHAR(255); 
  DECLARE _msg_id VARCHAR(16);
  DECLARE _timestamp int(11) unsigned;
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;

  CALL pageToLimits(_page, _offset, _range);  



  SELECT  sys_id FROM  (SELECT sys_id  FROM channel c 
  WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id) 
  ORDER BY c.sys_id  DESC  LIMIT _offset, _range) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id; 

  SELECT ref_sys_id FROM read_channel WHERE  uid = _uid INTO _old_ref_sys_id;

  IF ( _ref_sys_id > IFNULL(_old_ref_sys_id,0)) THEN  

     UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
     WHERE sys_id <= _ref_sys_id   AND 
     JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;

    INSERT INTO read_channel(uid,ref_sys_id,ctime) SELECT _uid,_ref_sys_id,UNIX_TIMESTAMP() 
    ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();
  END IF; 


  SELECT 
   _page as `page`,
    c.sys_id,
    c.author_id,  
    c.message,   
    c.message_id, 
    c.thread_id, 
    c.is_forward, 
    c.attachment, 
    CASE WHEN LTRIM(RTRIM(c.attachment))='' OR  c.attachment IS NULL THEN 0 ELSE 1 END is_attachment, 
    c.status,     
    c.ctime,      
    c.metadata,
    firstname, lastname, CONCAT(firstname, ' ', lastname) fullname,
    CASE WHEN _old_ref_sys_id  <  c.sys_id THEN 1 ELSE 0 END is_notify,  
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
    THEN  1 ELSE 0 END is_seen
  FROM 
    (SELECT sys_id FROM channel c  
      WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id) 
    ORDER BY c.sys_id  DESC LIMIT _offset, _range) s
  INNER JOIN channel c  on c.sys_id = s.sys_id
  INNER JOIN(yp.drumate d)
  ON author_id=d.id
 
  ORDER BY c.sys_id DESC;

END$

DELIMITER ;



