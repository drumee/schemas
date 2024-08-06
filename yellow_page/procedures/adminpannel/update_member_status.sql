DELIMITER $

DROP PROCEDURE IF EXISTS `update_member_status`$
CREATE PROCEDURE `update_member_status`(
  IN _drumate_id  VARCHAR(16),
  IN _status VARCHAR(25)
 )
BEGIN
    
  UPDATE entity SET status=_status WHERE id = _drumate_id;
  UPDATE entity SET `settings` = 
    JSON_SET(`settings`, CONCAT("$.status_date"), UNIX_TIMESTAMP()) 
    WHERE id=_drumate_id;

END $


DELIMITER ;