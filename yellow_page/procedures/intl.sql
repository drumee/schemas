DELIMITER $

-- =========================================================
--
-- LOCALE
--
-- =========================================================


-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_add`$
CREATE PROCEDURE `intl_add`(
  IN _code VARCHAR(128),
  IN _en TEXT,
  IN _fr TEXT,
  IN _ru TEXT,
  IN _zh TEXT
)
BEGIN
  DECLARE _cat VARCHAR(30) DEFAULT 'ui';
  IF _code REGEXP '^_' THEN
    SELECT 'page' INTO _cat;
  END IF;
  INSERT INTO intl VALUES(null, _code, _cat, _fr, _en, _ru, _zh);
  SELECT sys_id as id, key_code, fr, en, ru, zh FROM intl WHERE key_code = _code;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_add_next`$
CREATE PROCEDURE `intl_add_next`(
  IN _code VARCHAR(128),
  IN _cat VARCHAR(128),
  IN _lng VARCHAR(28),
  IN _des TEXT
)
BEGIN
  REPLACE INTO languages VALUES(null, _code, _cat, _lng, _des);
  SELECT LAST_INSERT_ID() AS id;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_delete_next`$
CREATE PROCEDURE `intl_delete_next`(
  IN _key VARCHAR(128),
  IN _cat VARCHAR(128)
)
BEGIN
  DELETE FROM languages WHERE key_code=_key AND category=_cat;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_delete`$
CREATE PROCEDURE `intl_delete`(
  IN _key VARCHAR(80)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DELETE FROM intl WHERE sys_id=_key OR (key_code=_key and category='ui');
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_list_next`$
CREATE PROCEDURE `intl_list_next`(
  IN _cat VARCHAR(80),
  IN _page TINYINT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  SET @rows_per_page=100;
  CALL pageToLimits(_page, _offset, _range);
  SELECT _page as `page`, sys_id as id, key_code, lng, `des` 
    FROM languages WHERE category=_cat
  ORDER BY key_code ASC LIMIT _offset, _range;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_keys_next`$
CREATE PROCEDURE `intl_keys_next`(
  IN _key VARCHAR(80),
  IN _cat VARCHAR(80)
)
BEGIN

  IF LENGTH(_key) < 3 THEN
    SET @pattern = CONCAT(TRIM(_key), '%');
  ELSE
    SET @pattern = CONCAT('%', TRIM(_key), '%');
  END IF;

  SELECT DISTINCT(key_code) AS content FROM languages WHERE 
    (key_code LIKE @pattern OR `des`LIKE @pattern) AND category=_cat 
    LIMIT 20;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_list_by_type`$
CREATE PROCEDURE `intl_list_by_type`(
  IN _type VARCHAR(16),
  IN _page TINYINT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  select _page as `page`, sys_id as id, key_code, fr, en, ru, zh from intl where category=_type
  ORDER BY key_code ASC LIMIT _offset, _range;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_get`$
CREATE PROCEDURE `intl_get`(
  IN _key VARCHAR(80)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  select sys_id as id, key_code, fr, en, ru, zh FROM intl WHERE 
    _key = sys_id OR (key_code=_key and category='ui');
END $


DROP PROCEDURE IF EXISTS `intl_get_next`$
CREATE PROCEDURE `intl_get_next`(
  IN _key VARCHAR(80),
  IN _cat VARCHAR(80)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  SELECT *, lng AS `name`, `des` AS `value`, sys_id AS id
    FROM languages WHERE key_code=_key AND category=_cat;
END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
-- DROP PROCEDURE IF EXISTS `intl_update`$
-- CREATE PROCEDURE `intl_update`(
--   IN _key VARCHAR(40),
--   IN _en TEXT,
--   IN _fr TEXT,
--   IN _ru TEXT,
--   IN _zh TEXT
-- )
-- BEGIN
--   DECLARE _cat VARCHAR(30) DEFAULT 'ui';
--   IF _key REGEXP '^_' THEN
--     SELECT 'page' INTO _cat;
--   END IF;
--   UPDATE intl SET en=_en, fr=_fr, ru=_ru, zh=_zh WHERE 
--     _key = sys_id OR (key_code=_key and category=_cat);
--   SELECT key_code, fr, en, ru, zh FROM intl WHERE 
--     _key = sys_id OR (key_code=_key and category=_cat);
-- END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
-- DROP PROCEDURE IF EXISTS `intl_update_by_id`$
-- CREATE PROCEDURE `intl_update_by_id`(
--   IN _id INTEGER,
--   IN _key VARCHAR(80),
--   IN _en TEXT,
--   IN _fr TEXT,
--   IN _ru TEXT,
--   IN _zh TEXT
-- )
-- BEGIN

--   DECLARE _cat VARCHAR(30) DEFAULT 'ui';
--   IF _key REGEXP '^_' THEN
--     SELECT 'page' INTO _cat;
--     SELECT lower(_key) INTO _key;
--   END IF;

--   UPDATE intl 
--     SET key_code=_key, en=_en, fr=_fr, ru=_ru, zh=_zh, category=_cat
--     WHERE _id = sys_id;
--   SELECT category, key_code, fr, en, ru, zh 
--     FROM intl 
--     WHERE _id = sys_id;
-- END $

-- =========================================================
-- Lexicon for ui
-- =========================================================
-- DROP PROCEDURE IF EXISTS `intl_update_by_id`$
DROP PROCEDURE IF EXISTS `intl_update_by_id_next`$
CREATE PROCEDURE `intl_update_by_id_next`(
  IN _id INTEGER,
  IN _value TEXT
)
BEGIN

  DECLARE _lng VARCHAR(30) DEFAULT 'ui';
  DECLARE _cat VARCHAR(30) DEFAULT 'ui';
  DECLARE _key VARCHAR(80) DEFAULT '';
  SELECT lng, category, key_code FROM languages 
    WHERE sys_id=_id INTO _lng, _cat, _key;
  IF _lng IS NOT NULL THEN 
    UPDATE languages SET `des`=_value WHERE sys_id=_id;
    SELECT *, sys_id id, 'previous' position FROM languages 
      WHERE key_code < _key AND lng=_lng AND category=_cat LIMIT 1;
    SELECT *, sys_id id, 'current' position FROM languages  WHERE sys_id=_id;
    SELECT *, sys_id id, 'next' position FROM languages 
      WHERE key_code > _key AND lng=_lng AND category=_cat LIMIT 1;
  END IF;
END $

-- =========================================================
-- Lexicon for error
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_error`$
CREATE PROCEDURE `intl_error`(
  IN _code VARCHAR(128),
  IN _level VARCHAR(20),
  IN _err_code INT(8),
  IN _fr TEXT,
  IN _en TEXT
)
BEGIN
  INSERT INTO intl VALUES(_code, 'error', _fr, _en);
  INSERT INTO error VALUES(_code, _level, _err_code);
END $

-- =========================================================
-- find rows in lexicon
-- =========================================================
DROP PROCEDURE IF EXISTS `intl_find`$
CREATE PROCEDURE `intl_find`(
  IN _arg VARCHAR(128)
)
BEGIN
  SET @arg = CONCAT('%', _arg, '%');
  SELECT * FROM intl WHERE key_code LIKE @arg OR fr LIKE @arg OR en LIKE @arg;
END $

-- =========================================================
-- search rows in lexicon
-- =========================================================
-- DROP PROCEDURE IF EXISTS `intl_search`$
DROP PROCEDURE IF EXISTS `intl_search_next`$
CREATE PROCEDURE `intl_search_next`(
  IN _arg VARCHAR(128),
  IN _cat VARCHAR(128),
  IN _page INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  IF LENGTH(_arg) < 3 THEN
    SET @arg = CONCAT(TRIM(_arg), '%');
  ELSE
    SET @arg = CONCAT('%', TRIM(_arg), '%');
  END IF;

  DROP TABLE IF EXISTS __tmp_search;
  CREATE TEMPORARY TABLE __tmp_search (
    `sys_id` int(11) unsigned,
    `key_code` varchar(40) NOT NULL,
    `category` varchar(40),
    `lng` varchar(20) NOT NULL,
    `des` text NOT NULL
  );

  INSERT INTO __tmp_search SELECT * FROM languages 
    WHERE category=_cat AND key_code LIKE @arg OR `des` LIKE @arg
    ORDER BY `key_code` ASC LIMIT _offset, _range;

  SELECT l.*, l.sys_id id FROM  __tmp_search t LEFT JOIN languages l ON 
    t.key_code=l.key_code WHERE l.category=_cat ORDER BY `key_code` ASC;
  -- SELECT 
END $


-- =========================================================
-- get_intl_msg
-- Get internationalized messages
-- =========================================================

DROP PROCEDURE IF EXISTS `get_intl_msg`$
CREATE PROCEDURE `get_intl_msg`(
  IN _key VARCHAR(64)
)
BEGIN

  SELECT * FROM intl WHERE key_code=_key;

END$

-- =========================================================
-- 
-- 
-- =========================================================

DROP PROCEDURE IF EXISTS `intl_get_by_group`$
CREATE PROCEDURE `intl_get_by_group`(
  IN _key VARCHAR(64)
)
BEGIN

  SELECT * FROM intl WHERE key_code LIKE CONCAT(_key, "%");

END$


DELIMITER ;

-- #####################
