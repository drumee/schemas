DELIMITER $

DROP PROCEDURE IF EXISTS `redirect_proc`$
CREATE PROCEDURE `redirect_proc`(
  IN _id VARCHAR(250),
  IN _fn VARCHAR(250),
  IN _arg JSON
)
BEGIN
  DECLARE _db VARCHAR(255);
  DECLARE _list VARCHAR(1000);
  DECLARE _i TINYINT(6) unsigned DEFAULT 0;

  SELECT CONCAT('`', db_name, '`') FROM entity 
    WHERE vhost=_id or id=_id or ident=_id INTO _db;
  IF JSON_TYPE(_arg) = 'ARRAY' THEN 
    SELECT _arg INTO _list;
  ELSE 
    SELECT JSON_ARRAY(_arg) INTO _list;
  END IF;

  IF _db != '' OR _db IS NOT NULL THEN
    SET @sx = CONCAT("CALL ",_db, ".", _fn, "(");
    WHILE _i < JSON_LENGTH(_list) DO 
      IF _i = JSON_LENGTH(_list) - 1 THEN 
        SET @ending = ")";
      ELSE
        SET @ending = ", ";
      END IF;
      SELECT CONCAT(@sx, QUOTE(get_json_array(_list, _i)), @ending) INTO @sx;
      SELECT _i + 1 INTO _i;
    END WHILE;

    PREPARE stmtx FROM @sx;
    EXECUTE stmtx;
    DEALLOCATE PREPARE stmtx;
  END IF;
END $
DELIMITER ;
