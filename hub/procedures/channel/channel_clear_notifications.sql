
DELIMITER $

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `channel_clear_notifications`$
CREATE PROCEDURE `channel_clear_notifications`(
  IN _uid VARCHAR(16)
)
BEGIN
  UPDATE channel SET 
    metadata=JSON_SET(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()) WHERE 
    JSON_EXISTS(metadata, "$._seen_") AND 
    NOT JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid));
END$


DROP PROCEDURE IF EXISTS `acknowledge_message`$
CREATE PROCEDURE `acknowledge_message`(
  IN _message_id VARCHAR(16),
  IN  _uid VARCHAR(16)
)
BEGIN
  DECLARE _ticket_id  int(11) ;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;

  SELECT sys_id FROM channel WHERE message_id=_message_id INTO _ref_sys_id;

  SELECT ref_sys_id FROM read_channel WHERE  uid = _uid INTO _old_ref_sys_id;

  SELECT CASE WHEN _ref_sys_id < IFNULL(_old_ref_sys_id,0) THEN IFNULL(_old_ref_sys_id,0)  ELSE _ref_sys_id END INTO _ref_sys_id;

  INSERT INTO read_channel(uid,ref_sys_id,ctime) SELECT _uid,_ref_sys_id,UNIX_TIMESTAMP() 
  ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();


  UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
  WHERE sys_id <= _ref_sys_id   AND 
  JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;
 
    SELECT ticket_id FROM map_ticket WHERE message_id = _message_id INTO _ticket_id;

    IF _ticket_id IS NOT NULL THEN 
      UPDATE channel c INNER JOIN map_ticket mt ON mt.message_id = c.message_id
      SET  c.metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
      WHERE c.sys_id <= _ref_sys_id   AND mt.ticket_id = _ticket_id AND
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;

      INSERT INTO yp.read_ticket_channel(uid,ticket_id , ref_sys_id,ctime) SELECT _uid,_ticket_id,_ref_sys_id,UNIX_TIMESTAMP() 
      ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();
    END IF;


  SELECT * FROM channel WHERE sys_id = _ref_sys_id;

END$  


DELIMITER ;
