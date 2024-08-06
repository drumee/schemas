
DELIMITER $

DROP PROCEDURE IF EXISTS `room_detail`$
CREATE PROCEDURE `room_detail`(
  IN _in JSON,
  OUT _out JSON
)
BEGIN
DECLARE _read_cnt INT ;
DECLARE _uid VARCHAR(16);
DECLARE _ref_sys_id BIGINT;
DECLARE _read_sys_id BIGINT default 0;  
DECLARE _message mediumtext;
DECLARE _metadata JSON;
DECLARE _attachment mediumtext;
DECLARE _ctime INT(11) unsigned;
 
 
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;

  SELECT  ref_sys_id FROM read_channel WHERE uid = _uid INTO _read_sys_id; 

	SELECT 
	  COUNT(sys_id)
	FROM 
    channel c  WHERE  c.sys_id > _read_sys_id INTO _read_cnt ;

  --   SELECT max(sys_id) FROM channel INTO _ref_sys_id;

  SELECT max(sys_id) 
  FROM  channel c 
  LEFT JOIN delete_channel dc  
      ON dc.ref_sys_id = sys_id AND uid = _uid
  WHERE  ref_sys_id IS NULL INTO _ref_sys_id;

  SELECT message, attachment, ctime, metadata FROM 
    channel  WHERE sys_id = _ref_sys_id 
    INTO _message, _attachment, _ctime, _metadata;

  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('read_cnt',_read_cnt )) INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('message',_message ))  WHERE _message IS NOT NULL INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('ctime',_ctime )) WHERE _ctime IS NOT NULL INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('attachment',_attachment )) WHERE _attachment IS NOT NULL INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), _metadata) WHERE _metadata IS NOT NULL INTO _out;

END$

DELIMITER ;
