DELIMITER $

DROP PROCEDURE IF EXISTS `custom_row_insert`$
CREATE PROCEDURE `custom_row_insert`(
  IN _name VARCHAR(80),
  IN _values MEDIUMTEXT
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _i INTEGER DEFAULT 0;
  DECLARE _l INTEGER DEFAULT 0;

  SELECT id FROM custom WHERE `name`=_name OR id=_name INTO _id;
  SELECT JSON_LENGTH(_values) INTO _l;
  SELECT CONCAT('INSERT INTO `', _id, '` VALUES(') INTO @__row;
  
  WHILE _i < _l DO 
    IF _i + 1 = _l THEN 
      SELECT CONCAT(
        @__row,
        JSON_EXTRACT(_values, CONCAT("$[", _i, "]")), ')'
      ) INTO @__row;
    ELSE
      SELECT CONCAT(
        @__row,
        JSON_EXTRACT(_values, CONCAT("$[", _i, "]")), ','
      ) INTO @__row;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;

  IF _i THEN 
    PREPARE stmt FROM @__row;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  
  SELECT * FROM custom ORDER BY sys_id DESC LIMIT 1;
END$

DELIMITER ;
