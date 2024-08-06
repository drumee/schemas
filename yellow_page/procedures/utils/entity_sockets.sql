DELIMITER $

DROP PROCEDURE IF EXISTS `hub_sockets`$
DROP PROCEDURE IF EXISTS `entity_sockets`$
CREATE PROCEDURE `entity_sockets`(
  IN _arg JSON
)
BEGIN
  DECLARE _list JSON;
  DECLARE _i TINYINT(6) unsigned DEFAULT 0;
  DECLARE _db VARCHAR(160);
  DECLARE _db_name VARCHAR(160);
  DECLARE _id VARCHAR(160);

  SET @exclude = '';
  -- SELECT JSON_TYPE(_arg);
  IF JSON_TYPE(_arg) IN('STRING', 'INTEGER') OR JSON_TYPE(_arg) IS NULL THEN 
    SELECT _arg INTO _id;
  ELSE 
    SELECT JSON_EXTRACT(_arg, "$.exclude") INTO _list;
    IF JSON_TYPE(_list) != 'ARRAY' THEN 
      SELECT JSON_ARRAY(_list) INTO _list;
    END IF;

    IF _list IS NOT NULL AND JSON_LENGTH(_list)>0 THEN
      SET @exclude = 'AND s.id NOT IN (';
      WHILE _i < JSON_LENGTH(_list) DO 
        IF _i = JSON_LENGTH(_list) - 1 THEN 
          SET @ending = ")";
        ELSE
          SET @ending = ", ";
        END IF;
        SELECT JSON_EXTRACT(_list, CONCAT("$[", _i, "]")) INTO @item;
        IF CAST(@item as VARCHAR(1000)) IN('null', 'undefined') THEN
          SELECT CONCAT(@exclude, '"null"', @ending) INTO @exclude;
        ELSE 
          SELECT CONCAT(@exclude, @item, @ending) INTO @exclude;
        END IF;
        SELECT _i + 1 INTO _i;
      END WHILE;
    END IF;

    SELECT JSON_VALUE(_arg, "$.hub_id") INTO _id;
    SELECT JSON_VALUE(_arg, "$.db_name") INTO _db;
  END IF;
  -- SELECT _list, _id, JSON_TYPE(_arg), @exclude;

  SELECT db_name FROM entity WHERE id=_id OR db_name=_db INTO _db_name;
  IF _db_name IS NOT NULL THEN 
    SELECT CONCAT(
      "SELECT distinct s.id socket_id, s.uid FROM socket s INNER JOIN ",
      _db_name, 
      ".permission p on s.uid=p.entity_id WHERE s.state='active' ",
      @exclude
    ) INTO @sx;
    PREPARE stmtx FROM @sx;
    EXECUTE stmtx;
    DEALLOCATE PREPARE stmtx;
  END IF;
END$

DELIMITER ;