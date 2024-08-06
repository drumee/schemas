DELIMITER $

DROP PROCEDURE IF EXISTS `ticket_add`$
CREATE PROCEDURE `ticket_add`(
  IN _message_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _metadata JSON 
  )
BEGIN
  INSERT INTO ticket(message_id,uid,metadata,utime )
  SELECT _message_id, _uid ,_metadata,UNIX_TIMESTAMP();
  SELECT *  FROM ticket WHERE message_id =_message_id;
END $

DELIMITER ;
