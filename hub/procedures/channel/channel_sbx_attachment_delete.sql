
DELIMITER $
DROP PROCEDURE IF EXISTS `channel_sbx_attachment_delete`$
CREATE PROCEDURE `channel_sbx_attachment_delete`(
  IN _msg_id VARCHAR(16),
  IN _hub_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _rid VARCHAR(16),
  OUT _out VARCHAR(16)
)
BEGIN
  DECLARE _cnt INT(6) DEFAULT 0;
  DECLARE _delete_cnt INT(6) DEFAULT 0;
  DECLARE _delete INT(6) DEFAULT 0;
    SELECT 0  INTO _cnt;
    SELECT 0  INTO _delete;

    DELETE FROM  attachment 
    WHERE  hub_id = _hub_id AND  uid= _uid AND rid=_rid AND message_id = _msg_id;
    SELECT 1 FROM attachment WHERE rid=_rid  AND  uid= _uid LIMIT 1 INTO _cnt;
  
    IF _cnt = 0  THEN 
      CALL permission_revoke(_rid, _uid );
    END IF ; 

    SELECT 1 FROM attachment WHERE rid=_rid  LIMIT 1 INTO _delete;

    SELECT NULL INTO _out; 
    IF _delete = 0 THEN 
      SELECT _rid INTO _out; 
      DELETE FROM media WHERE id =_rid;
     
    END IF ; 

END$


DELIMITER ;
