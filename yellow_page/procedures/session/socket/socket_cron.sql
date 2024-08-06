DELIMITER $

DROP PROCEDURE IF EXISTS `socket_cron`$
CREATE PROCEDURE `socket_cron`(
)
BEGIN
  DELETE FROM socket WHERE `state` = 'idle' 
  AND ctime < unix_timestamp() - 24*60*60;
END$

DELIMITER ;
