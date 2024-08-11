DELIMITER $


DROP PROCEDURE IF EXISTS `contact_sync_update`$
CREATE PROCEDURE `contact_sync_update`(
  IN _uid VARCHAR(16)
)
BEGIN
  UPDATE contact_sync SET status='update' WHERE status <>'delete' AND uid =_uid; 
END$


DELIMITER ;