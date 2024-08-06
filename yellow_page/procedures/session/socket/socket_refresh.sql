DELIMITER $
DROP PROCEDURE IF EXISTS `socket_refresh`$
CREATE PROCEDURE `socket_refresh`(
  IN _server VARCHAR(256) CHARACTER SET ascii,
  IN _list JSON
)
BEGIN
  DECLARE _index INT(4) DEFAULT 0;
  DECLARE _length INT(4) DEFAULT 0;
  DECLARE _socket_id VARCHAR(60) CHARACTER SET ascii;
  DECLARE _failed BOOLEAN DEFAULT 0;
  
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _failed = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  IF JSON_LENGTH(_list) IS NULL THEN
    SELECT 0 INTO _length;
  ELSE
    SELECT JSON_LENGTH(_list) INTO _length;
  END IF;

  START TRANSACTION;

  WHILE _index < _length DO 
    SELECT JSON_VALUE(_list, CONCAT("$[", _index, "]")) INTO _socket_id;
    REPLACE INTO socket_active SELECT _socket_id, UNIX_TIMESTAMP();
    SELECT _index + 1 INTO _index;
  END WHILE;

  DELETE FROM socket_active WHERE (unix_timestamp()- `timestamp`) > 30;
  DELETE FROM socket WHERE id NOT IN ( SELECT id FROM socket_active );
  DELETE FROM conference WHERE socket_id NOT IN ( SELECT id FROM socket );

  IF _failed THEN
    ROLLBACK;
  ELSE
    COMMIT;
  END IF;

END$

DELIMITER ;
