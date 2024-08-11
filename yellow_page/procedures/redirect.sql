DELIMITER $

-- =========================================================
--
-- REDIRECT PROCEDURES CALLS TO PROPER DATABASE
--
-- =========================================================

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `get_stylesheets`$
CREATE PROCEDURE `get_stylesheets`(
  IN _key VARCHAR(250)
)
BEGIN
  DECLARE _db VARCHAR(255);

  IF _key='' OR _key IS NULL THEN
    SELECT 'XXXXXXX' INTO _key;
  END IF;
  SELECT CONCAT('`', db_name, '`') FROM entity WHERE vhost=_key or id=_key or ident=_key INTO _db;
  IF _db != '' OR _db IS NOT NULL THEN
    SET @s1 = CONCAT("CALL ",_db, ".style_get_files()");

    PREPARE stmt FROM @s1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

END $

-- =========================================================
-- TO BE DEPRACTED
-- =========================================================
DROP PROCEDURE IF EXISTS `get_fonts`$
CREATE PROCEDURE `get_fonts`(
  IN _key VARCHAR(250)
)
BEGIN
  DECLARE _db VARCHAR(255);

  IF _key='' OR _key IS NULL THEN
    SELECT 'XXXXXXX' INTO _key;
  END IF;
  SELECT CONCAT('`', db_name, '`') FROM entity WHERE vhost=_key or id=_key or ident=_key INTO _db;

  IF _db != '' OR _db IS NOT NULL THEN
    SET @s1 = CONCAT("CALL ",_db, ".font_list_all()");

    PREPARE stmt FROM @s1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

END $


-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `redirect`$
CREATE PROCEDURE `redirect`(
  IN _fn VARCHAR(250),
  IN _key VARCHAR(250)
)
BEGIN
  DECLARE _db VARCHAR(255);

  SELECT CONCAT('`', db_name, '`') FROM entity WHERE vhost=_key or id=_key or ident=_key INTO _db;

  IF _db != '' OR _db IS NOT NULL THEN
    SET @s1 = CONCAT("CALL ",_db, ".", _fn, "()");

    PREPARE stmt FROM @s1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `forward_proc`$
CREATE PROCEDURE `forward_proc`(
  IN _id VARCHAR(250),
  IN _fn VARCHAR(250),
  IN _arg MEDIUMTEXT
)
BEGIN
  DECLARE _db VARCHAR(255);

  SELECT CONCAT('`', db_name, '`') FROM entity 
    WHERE vhost=_id or id=_id or ident=_id INTO _db;

  IF _db != '' OR _db IS NOT NULL THEN
    SET @sx = CONCAT("CALL ",_db, ".", _fn, "(", _arg, ")");

    PREPARE stmtx FROM @sx;
    EXECUTE stmtx;
    DEALLOCATE PREPARE stmtx;
  END IF;
  -- SELECT _db, @s1;
END $

-- =========================================================
--
-- =========================================================
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
  -- SELECT _db, @s1;
END $
-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `get_seo`$
CREATE PROCEDURE `get_seo`(
  IN _key VARCHAR(250),
  IN _hashtag VARCHAR(128),
  IN _lang VARCHAR(128)
)
BEGIN
  DECLARE _db VARCHAR(255);
  DECLARE _dn VARCHAR(255);

  -- SELECT vhost FROM entity WHERE vhost=_key or id=_key or ident=_key INTO _dn;
  select CONCAT('`', db_name, '`') from entity left join vhost using(id) where fqdn=_key INTO _db;
  IF _db != '' OR _db IS NOT NULL THEN
    SET @s1 = CONCAT("CALL ",_db, ".seo_get(", quote(_hashtag), ",", quote(_lang), ")");

    PREPARE stmt FROM @s1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

END $

DELIMITER ;

-- #####################
