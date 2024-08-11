DELIMITER $


-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `custom_table_register`$
CREATE PROCEDURE `custom_table_register`(
  IN _name VARCHAR(80),
  IN _uid VARCHAR(16)
)
BEGIN
  INSERT INTO custom VALUES(null, yp.uniqueId(), _name, _uid, UNIX_TIMESTAMP());
  SELECT *, id AS table_name FROM custom WHERE `name` = _name;
END$

-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `custom_table_get`$
CREATE PROCEDURE `custom_table_get`(
  IN _name VARCHAR(80)
)
BEGIN
  SELECT *, id AS table_name FROM custom WHERE `name` = _name OR id=_name;
END$

-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `custom_table_delete`$
CREATE PROCEDURE `custom_table_delete`(
  IN _name VARCHAR(80)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _count INTEGER;
  SELECT id FROM custom WHERE `name`=_name INTO _id;
  IF _id IS NOT NULL THEN 
    DELETE FROM  custom WHERE `id`=_id;
    SET @s = CONCAT("DROP TABLE `", _id, "`;");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT _name AS name, _id AS id, 'deleted';
  END IF;
END$

-- =======================================================================
-- 
-- =======================================================================
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
