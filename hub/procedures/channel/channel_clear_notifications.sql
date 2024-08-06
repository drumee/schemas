
DELIMITER $

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


DELIMITER ;
