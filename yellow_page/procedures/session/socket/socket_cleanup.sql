DELIMITER $

DROP PROCEDURE IF EXISTS `socket_cleanup`$
CREATE PROCEDURE `socket_cleanup`(
  IN _server VARCHAR(258)
)
BEGIN
  -- DELETE FROM socket WHERE `state` = 'idle' AND ctime < unix_timestamp() - 24*60*60;
  -- UPDATE socket SET `state` = 'idle' WHERE `server`=_server;
END$

DELIMITER ;
