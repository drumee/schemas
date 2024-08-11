
DELIMITER $
-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `channel_notify_messages`$
CREATE PROCEDURE `channel_notify_messages`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT 
    COUNT(1)  read_cnt
  FROM channel WHERE 
  JSON_EXISTS(metadata, "$._seen_") AND  
  NOT JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)); 
END$

DELIMITER ;
