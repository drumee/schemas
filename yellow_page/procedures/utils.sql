DELIMITER $

-- =========================================================
--
-- UTILITIES
--
-- =========================================================

-- =========================================================
-- Get offset and range from page number
-- =========================================================
DROP PROCEDURE IF EXISTS `pageToLimits`$
CREATE PROCEDURE `pageToLimits`(
  IN _page VARCHAR(32),
  OUT _offset BIGINT,
  OUT _range BIGINT
)
BEGIN
  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=20;
  END IF;
  SELECT (_page - 1)*@rows_per_page, @rows_per_page INTO _offset,_range;
END $




-- =========================================================
-- find rows in lexicon
-- =========================================================
DROP PROCEDURE IF EXISTS `lang_search`$
CREATE PROCEDURE `lang_search`(
  IN _arg VARCHAR(128),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT *, _page as `page`, IF(lcid=_arg, 100, 0)
    + IF(locale_en=_arg, 100, 0)
    + IF(locale=_arg, 100, 0)
    + IF(code=_arg, 50, 0)
    + IF(locale_en LIKE concat(_arg, "%"), 25 ,0)
    + IF(locale_en LIKE concat("%", _arg, "%"), 13, 0)
    + IF(locale LIKE concat(_arg, "%"), 25,0)
    + IF(locale LIKE concat("%", _arg, "%"), 13, 0)
    + MATCH(locale_en, locale, comment)
      against(_arg IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) AS score
    FROM `language` HAVING score > 25
    ORDER BY score DESC LIMIT _offset, _range;
END $

-- =========================================================
-- Gets list of available languages from yellow page.
-- =========================================================
DROP PROCEDURE IF EXISTS `get_laguages`$
CREATE PROCEDURE `get_laguages`(
  IN _name         VARCHAR(200),
  IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT _page as `page`, code, lcid, locale_en, locale, flag_image FROM yp.language WHERE `state` = 'active'
    AND code NOT IN (SELECT locale FROM language WHERE state = 'active' OR state = 'replaced')
    AND locale_en LIKE CONCAT(TRIM(IFNULL(_name, '')), '%')
    ORDER BY locale_en ASC LIMIT _offset, _range;
END$

-- =========================================================
--
-- TECHNICAL SUPPORT
--
-- =========================================================

-- =========================================================
-- get_error_map
-- Get errors map
-- =========================================================

DROP PROCEDURE IF EXISTS `get_error_map`$
CREATE PROCEDURE `get_error_map`(
  IN _code VARCHAR(64)
)
BEGIN

  SELECT * FROM error_view WHERE msg_key=_code;

END$


DROP PROCEDURE IF EXISTS `hot_tech`$
CREATE PROCEDURE `hot_tech`(
  IN _p VARCHAR(8)
)
BEGIN
  DECLARE prio INT DEFAULT 0;
  SELECT *, CONCAT(firstname, ' ', lastname) as fullname
    FROM team WHERE domain='tech' AND priority<=_p;

END$


-- =========================================================
--
-- SESSIONS MANAGEMNT PART
--
-- =========================================================

-- =========================================================
-- Cleanup sessions table
-- =========================================================
DROP PROCEDURE IF EXISTS `cleanup_sessions`$
CREATE PROCEDURE `cleanup_sessions`(
  IN session_ttl INT(11)
)
BEGIN

  DELETE FROM sessions  WHERE cast((UNIX_TIMESTAMP() - update_time) as SIGNED) > session_ttl;

END$

-- =========================================================
-- Cleanup sessions table
-- =========================================================
DROP PROCEDURE IF EXISTS `logout`$
CREATE PROCEDURE `logout`(
  IN _key VARCHAR(128),
  IN _ip VARCHAR(120)
)
BEGIN

  DELETE FROM sessions  WHERE (id=_key) OR (user_id=_key AND last_ip=_ip);

END$


-- =========================================================
-- Check session id
-- =========================================================
DROP PROCEDURE IF EXISTS `check_sid`$
CREATE PROCEDURE `check_sid`(
  IN _sid VARCHAR(128),
  IN _ip VARCHAR(80),
  IN _ua VARCHAR(255),
  IN _vhost VARCHAR(512)
)
BEGIN
  DECLARE _ip VARCHAR(80);
  DECLARE _uname VARCHAR(80);
  DECLARE _uid VARCHAR(16);
  DECLARE _host_id VARCHAR(16);
  DECLARE _exp VARCHAR(80);
  DECLARE _domain VARCHAR(256);
  SELECT IFNULL(domain, main_domain()) FROM vhost WHERE fqdn=_vhost INTO _domain;
  SELECT IF((UNIX_TIMESTAMP() - update_time)<= ttl, 'SESSION_OK', 'SESSION_EXPIRED') AS exp,
    user_id, entity.ident, entity.id as host_id, sessions.id
    FROM sessions INNER JOIN entity ON user_id=entity.id 
      WHERE sessions.id=_sid /*AND ua=_ua */
      INTO _exp, _uid, _uname, _host_id;
    -- FROM sessions WHERE id=sid  AND last_ip=ip AND ua=_ua INTO _exp, _uid, _uname, _host_id;

    SELECT CASE
       WHEN _uid IS NULL THEN 'SESSION_NOT_FOUND'
       WHEN _uid = 'ffffffffffffffff'  THEN 'SESSION_ANONYMOUS'
--       WHEN _host_id != "xxxx" THEN 'SESSION_GUEST'
       ELSE 'SESSION_OK'
    END AS status, _uid AS uid, _uname AS username, _exp AS expired, 
      _host_id AS host_id, _domain AS domain;
END$


-- =========================================================
-- update_session
-- =========================================================

DROP PROCEDURE IF EXISTS `update_session`$
CREATE PROCEDURE `update_session`(
  IN sid VARCHAR(64),
  IN uid VARCHAR(16),
  IN uname VARCHAR(80),
  IN _host VARCHAR(16)
)
BEGIN

  DECLARE _now INT(12) DEFAULT 0;

  SELECT UNIX_TIMESTAMP() into _now;

  UPDATE sessions SET update_time=UNIX_TIMESTAMP(), 
    user_id=uid, username=uname, host_id=_host WHERE id=sid;
  IF uid != 'ffffffffffffffff' THEN
    UPDATE drumate SET connexion_time=_now WHERE id=uid;
  END IF;

END$


-- =========================================================
-- create_anon_session
-- =========================================================

-- DROP PROCEDURE IF EXISTS `create_anon_session_old`$
-- CREATE PROCEDURE `create_anon_session_old`(
--   IN _sid VARBINARY(64),
--   IN _uid VARBINARY(16),
--   IN _uname VARCHAR(80),
--   IN _ip VARCHAR(255),
--   IN _ua VARCHAR(255),
--   IN _action VARCHAR(255),
--   IN _vhost VARCHAR(512)
-- )
-- BEGIN

--   DECLARE _now INT(11) DEFAULT 0;
--   DECLARE default_ttl INT DEFAULT 86400;
--   DECLARE _domain VARCHAR(256);

--   SELECT UNIX_TIMESTAMP() into @n;
--   SELECT IFNULL(`domain`, main_domain()) FROM vhost 
--     WHERE fqdn=_vhost INTO _domain;

--   INSERT INTO
--     sessions (`id`,`user_id`,`username`,`domain`,`update_time`,`start_time`,`ttl`, `last_ip`, `ua`, `action`)
--     VALUES(_sid, _uid, _uname, _domain, @n, @n, default_ttl,  _ip, _ua, _action);
--   SELECT _domain AS domain;
-- END$

-- =========================================================
-- trace
-- =========================================================

DROP PROCEDURE IF EXISTS `create_anon_session`$
CREATE PROCEDURE `create_anon_session`(
  IN _sid VARCHAR(64),
  IN _uid VARCHAR(16),
  IN _uname VARCHAR(80),
  IN _ip VARCHAR(255),
  IN _ua VARCHAR(255)
  -- IN _vhost VARCHAR(512)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE default_ttl INT DEFAULT 86400;  
  -- DECLARE _domain VARCHAR(256);

  SELECT UNIX_TIMESTAMP() into @n;
  -- SELECT IFNULL(`domain`, main_domain()) FROM vhost 
  --   WHERE fqdn=_vhost INTO _domain;

  IF _sid IN (NULL, 'null', 'undefined', '0', '', '---') THEN 
    SELECT CONCAT(yp.uniqueId(), yp.uniqueId(), yp.uniqueId(), yp.uniqueId()) INTO _sid;
  END IF;
  INSERT INTO
    sessions (`id`,`user_id`,`username`,`domain`,`update_time`,`start_time`,`ttl`, `last_ip`, `ua`, `action`)
    VALUES(_sid, _uid, _uname, main_domain(), @n, @n, default_ttl,  _ip, _ua, 'insert');
    SELECT _sid AS session_id;
END$



-- =========================================================
-- trace
-- =========================================================

DROP PROCEDURE IF EXISTS `trace`$
CREATE PROCEDURE `trace`(
  IN sid VARCHAR(64),
  IN _action VARCHAR(40)
)
BEGIN

  SET @s1 = CONCAT("INSERT INTO log ",
   "(`username`, `start_time`, `update_time`, `last_ip`, `req_uri`, `referer`, `ua`, `action`) "
   "SELECT username, start_time, update_time, last_ip, req_uri, referer, ua, ", quote(_action),
   " FROM sessions WHERE id=", quote(sid), " ORDER BY update_time DESC LIMIT 1") ;

PREPARE stmt FROM @s1;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

END$


-- =========================================================
-- trace
-- =========================================================

DROP PROCEDURE IF EXISTS `log_activity`$
CREATE PROCEDURE `log_activity`(
  IN _uid      varchar(16),
  IN _username varchar(40),
  IN _ip       varchar(40),
  IN _ip_fwd   varchar(40),
  IN _req_uri  varchar(255),
  IN _referer  varchar(255),
  IN _ua       varchar(255),
  IN _action   varchar(40)
)
BEGIN

  INSERT INTO log values(
    sha2(uuid(),224),
    sha2(uuid(),224),
    _uid,
    _username,
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP(),
    0,
    _ip,
    _ip_fwd,
    _req_uri,
    _referer,
    _ua,
    _action
  );
END$



-- ***********************************************************************
-- MAINTENACE SECTION
-- ***********************************************************************

DROP PROCEDURE IF EXISTS `list_drumate_db`$
CREATE PROCEDURE `list_drumate_db`(
)
BEGIN

  select db_name from entity where type='drumate';

END $

-- =======================================================================
-- Maintenace utils
-- =======================================================================
DROP PROCEDURE IF EXISTS `list_hub_db`$
CREATE PROCEDURE `list_hub_db`(
)
BEGIN

  select db_name from entity where type='community' or type='hub';

END $

-- =======================================================================
-- Maintenace utils
-- =======================================================================
DROP PROCEDURE IF EXISTS `list_all_db`$
CREATE PROCEDURE `list_all_db`(
)
BEGIN

  select db_name from entity where type='drumate' or type='community' or type='hub';

END $

-- =======================================================================
-- TO BE EXPORTED
-- =======================================================================


-- =======================================================================
-- yp_get_cities
-- =======================================================================
DROP PROCEDURE IF EXISTS `yp_get_cities`$
CREATE PROCEDURE `yp_get_cities`(
  IN _country_id INT(11),
  IN _page INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT c.*,_page as `page` FROM cities c INNER JOIN states s ON s.id=c.id INNER JOIN countries co
    ON co.id=_country_id ORDER BY `name` ASC LIMIT _offset, _range;
END $

-- =======================================================================
-- yp_get_cities
-- =======================================================================
DROP PROCEDURE IF EXISTS `utils_search_cities`$
CREATE PROCEDURE `utils_search_cities`(
  IN _name VARCHAR(80),
  IN _page INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    DISTINCT c.name city_name ,_page as `page`
  FROM cities c 
  WHERE TRIM("'" FROM c.name) LIKE CONCAT(_name, "%") ORDER BY `city_name` 
  ASC LIMIT _offset, _range;
END $

-- =======================================================================
-- yp_get_countries
-- =======================================================================
DROP PROCEDURE IF EXISTS `yp_get_countries`$
CREATE PROCEDURE `yp_get_countries`()
BEGIN
  select * from countries ORDER BY `name` ASC;
END $

-- =======================================================================
-- utils_get_countries
-- =======================================================================
DROP PROCEDURE IF EXISTS `utils_get_countries`$
CREATE PROCEDURE `utils_get_countries`(  
  IN _page INT(4),
  IN _length INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  IF _length IS NOT NULL THEN 
    SET @rows_per_page = _length;
  ELSE
    SET @rows_per_page = 20;
  END IF;
  CALL pageToLimits(_page, _offset, _range);
  select *,_page as `page` from countries ORDER BY `name` ASC LIMIT _offset, _range;
END $

-- =======================================================================
-- utils_get_countries
-- =======================================================================
DROP PROCEDURE IF EXISTS `utils_search_countries`$
CREATE PROCEDURE `utils_search_countries`(  
  IN _name VARCHAR(40),
  IN _page INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * ,_page as `page` FROM countries WHERE 
  `name` LIKE CONCAT("%", _name, "%") 
  ORDER BY `name` ASC LIMIT _offset, _range;
END $

-- =======================================================================
-- yp_find_city
-- =======================================================================
DROP PROCEDURE IF EXISTS `yp_find_city`$
CREATE PROCEDURE `yp_find_city`(
  IN _pattern VARCHAR(84),
  IN _cc_iso VARCHAR(80)
)
BEGIN
  IF _cc_iso='' OR _cc_iso IS NULL THEN
    select city.id, name_utf8, fr, en, region, IF(name_ascii = _pattern, 1, 0) AS relevance
    from city join country using(cc_iso)
    WHERE name_ascii = _pattern OR name_ascii LIKE concat(_pattern, "%") ORDER BY relevance DESC LIMIT 30;
  ELSE
    select city.id, name_utf8, fr, en, region, IF(name_ascii = _pattern, 1, 0) AS relevance
    from city join country using(cc_iso)
    WHERE cc_iso=_cc_iso AND (name_ascii = _pattern OR name_ascii LIKE concat(_pattern, "%"))
    ORDER BY relevance DESC LIMIT 30;
  END IF;

END $

-- =======================================================================
-- yp_find_country
-- =======================================================================
DROP PROCEDURE IF EXISTS `yp_find_country`$
CREATE PROCEDURE `yp_find_country`(
  IN _pattern VARCHAR(84)
)
BEGIN

  select *, MATCH(`fr`, `en`) against(concat(_pattern, '*') IN BOOLEAN MODE) as relevance
  from country having relevance > 1 ORDER BY relevance DESC LIMIT 30;

END $

-- =======================================================================
-- yp_find_country
-- =======================================================================
DROP PROCEDURE IF EXISTS `yp_find_language`$
CREATE PROCEDURE `yp_find_language`(
  IN _pattern VARCHAR(84)
)
BEGIN

  select *, if(locale='', locale_en, concat (locale_en, ' - ', locale)) as content
  from `language` WHERE locale LIKE concat("%", _pattern, "%") or locale_en LIKE concat("%", _pattern, "%")
  LIMIT 20;

END $


-- =======================================================================
-- available_ident
-- =======================================================================
DROP PROCEDURE IF EXISTS `available_ident`$
CREATE PROCEDURE `available_ident`(
  IN _key VARCHAR(84)
)
BEGIN
  SELECT _key AS ident, (SELECT NOT EXISTS (SELECT ident FROM entity WHERE ident=_key)) AS available;
END $


-- =======================================================================
-- get_unique_id
-- =======================================================================
DROP PROCEDURE IF EXISTS `get_unique_id`$
CREATE PROCEDURE `get_unique_id`()
BEGIN
  SELECT yp.uniqueId() AS id;
END $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `default_page`$
CREATE PROCEDURE `default_page`(
  IN  _hashtag varchar(255),
  IN  _lang varchar(25),
  OUT _res varchar(512)
)
BEGIN
  -- DECLARE _res VARCHAR(512);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _tmp VARCHAR(512);
  DECLARE _db_name VARCHAR(30);
  -- DECLARE _id VARCHAR(16);
  SELECT home_dir, db_name FROM entity WHERE id=(
    SELECT conf_value FROM yp.sys_conf WHERE conf_key='block_cdn_id'
  ) INTO _home_dir, _db_name;

  SET @_id='';

  SET @s = CONCAT("SELECT id FROM `", 
    _db_name, "`.`block` LEFT JOIN `", _db_name, "`.`block_history` on block.id=master_id ",
    " WHERE hashtag='", _hashtag, "' AND lang='", _lang, "' AND isonline=1 INTO @_id");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  -- SELECT @s;
  IF @_id = '' THEN
    SET @s = CONCAT("SELECT id FROM `", 
      _db_name, "`.`block` LEFT JOIN `", _db_name, "`.`block_history` on block.id=master_id ",
      " WHERE hashtag='", _hashtag, "' AND lang='en' AND isonline=1 INTO @_id");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  SELECT CONCAT(_home_dir, '/Block/', @_id) INTO _res;
END$


-- =======================================================================
-- available_ident
-- =======================================================================
DROP PROCEDURE IF EXISTS `test_sjon`$
CREATE PROCEDURE `test_sjon`(
  IN _json JSON
)
BEGIN

  insert into test values( uniqueId(), _json);

END $


-- =======================================================================
-- get_dbname_by_entityid
-- =======================================================================
DROP PROCEDURE IF EXISTS `get_dbname_by_entityid`$
CREATE PROCEDURE `get_dbname_by_entityid`(_id VARCHAR(16))
BEGIN
  SELECT db_name FROM  entity WHERE id =_id;
END $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `hubs_watermark`$
-- CREATE PROCEDURE `hubs_watermark`(
--   IN _lang VARCHAR(10)
-- )
-- BEGIN
--   IF _lang IN ('en', 'fr', 'ru', 'zh') THEN  
--     SELECT COUNT(*) AS level FROM entity 
--       WHERE JSON_UNQUOTE(JSON_EXTRACT(settings, "$.language")) = _lang 
--         AND area='pool';
--   ELSE  
--     SELECT COUNT(*) FROM entity 
--       WHERE JSON_UNQUOTE(JSON_EXTRACT(settings, "$.language")) = 'en' 
--         AND area='pool' INTO @_en;
--     SELECT COUNT(*) FROM entity 
--       WHERE JSON_UNQUOTE(JSON_EXTRACT(settings, "$.language")) = 'fr' 
--         AND area='pool' INTO @_fr;
--     SELECT COUNT(*) FROM entity 
--       WHERE JSON_UNQUOTE(JSON_EXTRACT(settings, "$.language")) = 'ru' 
--         AND area='pool' INTO @_ru;
--     SELECT COUNT(*) FROM entity 
--       WHERE JSON_UNQUOTE(JSON_EXTRACT(settings, "$.language")) = 'zh' 
--         AND area='pool' INTO @_zh;
--     SELECT @_en AS en, @_fr AS fr, @_ru AS ru, @_zh AS zh;
--   END IF;
-- END$

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `watermark`$
CREATE PROCEDURE `watermark`(
  IN _type VARCHAR(10)
)
BEGIN
  SELECT COUNT(*) AS en FROM entity WHERE area='pool' AND  type = _type;
END$



-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `unique_ident`$
CREATE PROCEDURE `unique_ident`(
  _ident VARCHAR(200)
)
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count TINYINT(8) DEFAULT 1;
  DECLARE _i TINYINT(6) DEFAULT 0;
  DECLARE _depth TINYINT(6) DEFAULT 0;
  
  SELECT _ident INTO _r;

  SELECT count(*) FROM entity WHERE ident = _r INTO _count;
  SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
  IF _ident regexp '[\_\-]\([0-9]+\)$' THEN 
    SELECT SUBSTRING_INDEX(_ident, '-', -1) INTO _depth;
    SELECT SUBSTRING_INDEX(_ident, '-', 1) INTO @base;
    WHILE _depth  < 1000 AND _count <> 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT CONCAT(@base, "-", _depth) INTO _r;
      SELECT count(*) FROM entity WHERE ident = _r INTO _count;
      SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
    END WHILE;
  ELSE 
    WHILE _count <> 0 DO
      SELECT count(*) FROM entity WHERE ident = _r INTO _count;
      SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
      IF _count >0 THEN 
        SELECT _i + 1 INTO _i;
        SELECT CONCAT(_ident, _i) INTO _r;
      END IF;
    END WHILE;
  END IF;
  SELECT _r AS ident;
END$

DELIMITER ;

-- #####################
