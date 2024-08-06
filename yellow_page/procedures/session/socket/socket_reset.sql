DELIMITER $
DROP PROCEDURE IF EXISTS `socket_reset`$
CREATE PROCEDURE `socket_reset`(
  IN _server VARCHAR(258)
)
BEGIN
  DECLARE _failed BOOLEAN DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _failed = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  START TRANSACTION;
  
  DELETE FROM conference WHERE socket_id IN (SELECT id FROM socket WHERE `server`=_server);
  DELETE FROM socket WHERE `server`=_server;

  IF _failed THEN
    ROLLBACK;
  ELSE
    COMMIT;
  END IF;

END$

DELIMITER ;
