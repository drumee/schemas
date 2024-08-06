DELIMITER $

DROP PROCEDURE IF EXISTS `user_sockets`$
CREATE PROCEDURE `user_sockets`(
  IN _arg JSON
)
BEGIN
  DECLARE _list JSON;
  DECLARE _i TINYINT(6) unsigned DEFAULT 0;

  IF JSON_TYPE(_arg) = 'ARRAY' THEN 
    SELECT _arg INTO _list;
  ELSE 
    SELECT JSON_ARRAY(_arg) INTO _list;
  END IF;
  SET @sx = "SELECT cookie, uid, id socket_id FROM socket WHERE `state`='active' AND `uid` IN (";
  SET @ending = NULL;
  WHILE _i < JSON_LENGTH(_list) DO 
    IF _i = JSON_LENGTH(_list) - 1 THEN 
      SET @ending = ")";
    ELSE
      SET @ending = ", ";
    END IF;
    SELECT CONCAT(@sx, QUOTE(get_json_array(_list, _i)), @ending) INTO @sx;
    SELECT _i + 1 INTO _i;
  END WHILE;
  -- SELECT  @sx;
  IF @ending IS NOT NULL THEN 
    PREPARE stmtx FROM @sx;
    EXECUTE stmtx;
    DEALLOCATE PREPARE stmtx;
  END IF;
END$

DELIMITER ;