DELIMITER $
-- =========================================================
-- set_env
-- set vars used later during the session
-- =========================================================

DROP FUNCTION IF EXISTS `set_env`$
CREATE FUNCTION `set_env`(
  _home_root VARCHAR(512),
  _date_format VARCHAR(512),
  _lc_time VARCHAR(512),
  _rows_per_page tinyint(4),
  _domain VARCHAR(512)
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  SET @home_root = _home_root;
  SET @dformat = _date_format;
  SET lc_time_names = _lc_time;
  SET @rows_per_page = _rows_per_page;
  SET @nobody = 'ffffffffffffffff';
  IF _domain='' or _domain=NULL THEN
    SET @domain_name =main_domain();
  ELSE
    SET @domain_name = _domain;
  END IF;

  RETURN @home_root;
END$

-- =========================================================
-- get_vhost, based on @domain_name
-- =========================================================
DROP FUNCTION IF EXISTS `get_vhost`$
CREATE FUNCTION `get_vhost`(
  _ident VARCHAR(80)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  SELECT CONCAT(_ident, '.', main_domain()) INTO _res;
  RETURN _res;
END$

-- =========================================================
-- get_vhost, based on @domain_name
-- =========================================================
-- DROP FUNCTION IF EXISTS `hubs_watermark`$
-- CREATE FUNCTION `hubs_watermark`(
--   _lang VARCHAR(2)
-- )
-- RETURNS INT(8) DETERMINISTIC
-- BEGIN
--   DECLARE _r INT(8);
--   select COUNT(*) FROM entity 
--     WHERE JSON_UNQUOTE(JSON_EXTRACT(settings, "$.language")) = _lang 
--       AND area='pool' INTO _r;
--   RETURN _r;
-- END$

-- =========================================================
--  @domain_name
-- =========================================================
DROP FUNCTION IF EXISTS `get_domain`$
CREATE FUNCTION `get_domain`(
  _ident VARCHAR(80)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  SELECT main_domain() INTO _res;
  RETURN _res;
END$

-- =========================================================
-- get_dmail, based on @domain_name
-- =========================================================
DROP FUNCTION IF EXISTS `get_dmail`$
CREATE FUNCTION `get_dmail`(
  _ident VARCHAR(80)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  SELECT CONCAT(_ident, '@', main_domain()) INTO _res;
  RETURN _res;
END$

-- =========================================================
-- Get ident, based on database name
-- =========================================================

DROP FUNCTION IF EXISTS `get_ident`$
-- CREATE FUNCTION `get_ident`(
-- )
-- RETURNS VARCHAR(80)
-- BEGIN
--   DECLARE _ident VARCHAR(120);
--   SELECT SUBSTRING_INDEX(database(), '_', -1) INTO _ident;
--   RETURN _ident;
-- END$

-- =========================================================
-- Get ident, based on database name
-- =========================================================
DROP FUNCTION IF EXISTS `get_area_id`$
CREATE FUNCTION `get_area_id`(
  _level VARCHAR(16),
  _owner VARCHAR(16)
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(120);
  SELECT id FROM area WHERE owner_id=_owner and level=_level INTO _res;
  SELECT IF(_res IS NULL, 'private', _res) INTO _res;
  RETURN _res;
END$

-- =========================================================
-- return number of attachments linked to a drum, if any
-- =========================================================

DROP FUNCTION IF EXISTS `has_attachment`$
CREATE FUNCTION `has_attachment`(
  _did VARCHAR(16)
)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE _a INT;
  SELECT  count(*) FROM attachments WHERE drum_id=_did INTO _a;
  RETURN _a;
END$

-- =========================================================
-- uniqueId
-- =========================================================
DROP FUNCTION IF EXISTS `uniqueId`$
CREATE FUNCTION `uniqueId`(

)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(16);
  SELECT CONCAT(SUBSTRING_INDEX(UUID(), '-', 1),SUBSTRING_INDEX(UUID(), '-', 1)) INTO _res;
  RETURN _res;
END$

-- =========================================================
-- make_db_name
-- =========================================================
DROP FUNCTION IF EXISTS `make_db_name`$
CREATE FUNCTION `make_db_name`(

)
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(20);
  SELECT concat(substring(uniqueId(),-1,1), '_', uniqueId()) INTO _res;
  RETURN _res;
END$


-- =========================================================
--
-- =========================================================
DROP FUNCTION IF EXISTS `ident_exists`$
CREATE FUNCTION `ident_exists`(
  _key  varchar(512)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  DECLARE _ident VARCHAR(80);

--  SELECT ident FROM signon WHERE ident=_key INTO _ident;
--  IF _ident IS NOT NULL OR _ident != '' THEN
--    RETURN TRUE;
--  END IF;

  SELECT ident FROM entity WHERE id=_key OR ident=_key INTO _ident;
  SELECT ident FROM organisation WHERE _ident IS NULL AND ident=_key INTO _ident;

  IF _ident IS NOT NULL OR _ident != '' THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;

END$



-- =========================================================
DROP FUNCTION IF EXISTS `user_exists`$
CREATE FUNCTION `user_exists`(
  _key  varchar(512) CHARACTER SET ascii
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(16);

--  SELECT ident FROM signon WHERE ident=_key INTO _ident;
--  IF _ident IS NOT NULL OR _ident != '' THEN
--    RETURN TRUE;
--  END IF;

  SELECT id FROM drumate WHERE id=_key or email = _key  LIMIT 1 INTO _id;


  IF _id IS NOT NULL OR _id != '' THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;

END$

-- =========================================================
--
-- =========================================================
DROP FUNCTION IF EXISTS `ident_exists_next`$
CREATE FUNCTION `ident_exists_next`(
  _key  varchar(512),
  _domain_name VARCHAR(1000)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  DECLARE _ident VARCHAR(80);

  SELECT ident FROM entity e INNER JOIN `domain` d ON e.dom_id = d.id 
    WHERE d.name=_domain_name AND e.ident = _key INTO _ident;

  IF _ident IS NOT NULL OR _ident != '' THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;

END$

-- =========================================================
--
-- =========================================================
DROP FUNCTION IF EXISTS `email_exists`$
CREATE FUNCTION `email_exists`(
  _key  varchar(512)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  DECLARE _email VARCHAR(512);

  SELECT email FROM drumate WHERE email=_key INTO _email;
   IF _email IS NOT NULL OR _email != '' THEN
     RETURN TRUE;
   END IF;

  RETURN FALSE;

END$



-- =========================================================
-- Utilities, finding db name
-- =========================================================
DROP FUNCTION IF EXISTS `dbname`$
CREATE FUNCTION `dbname`(
  _ident VARCHAR(128)
)
RETURNS VARCHAR(128) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(128);
  SELECT db_name FROM entity WHERE ident=_ident or id=_ident into _res;
  RETURN _res;
END$



-- =========================================================
-- Utilities, finding db name
-- =========================================================
DROP FUNCTION IF EXISTS `hub_id_old`$
CREATE FUNCTION `hub_id_old`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(16);
  DECLARE _vhost VARCHAR(1024);

  IF _key NOT REGEXP '^(.+)\\\.(.+)' THEN
    SELECT concat(ident, '.', yp.get_domain_name(ident)) FROM entity 
      WHERE ident=_key OR id=_key INTO _vhost;
  END IF;

  SELECT id FROM vhost INNER JOIN entity using(id) WHERE fqdn=_vhost INTO _res;
  IF _res IS NULL THEN 
    SELECT e.id FROM entity e INNER JOIN domain d on 
    e.dom_id=d.id WHERE e.id=_key INTO _res;
  END IF;
  RETURN _res;
END$


DROP FUNCTION IF EXISTS `hub_id`$
CREATE FUNCTION `hub_id`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(16);
  DECLARE _vhost VARCHAR(1024);

  IF _key NOT REGEXP '^(.+)\\\.(.+)' THEN
    SELECT concat(hubname, '.', yp.get_domain_name(hubname)) FROM hub 
      WHERE hubname=_key OR id=_key INTO _vhost;
  END IF;

  SELECT id FROM vhost INNER JOIN entity using(id) 
    WHERE fqdn=_vhost OR fqdn=CONCAT(_key, '.', yp.get_domain_name(_key)) INTO _res;
  IF _res IS NULL THEN 
    SELECT e.id FROM entity e INNER JOIN domain d on 
    e.dom_id=d.id WHERE e.id=_key INTO _res;
  END IF;
  RETURN _res;
END$



-- =========================================================
-- Utilities, finding db name
-- =========================================================
DROP FUNCTION IF EXISTS `backquoted_dbname`$
CREATE FUNCTION `backquoted_dbname`(
  _key VARCHAR(250)
)
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(255);

  SELECT CONCAT('`', db_name, '`') FROM entity WHERE id=_key or ident=_key or vhost=_key INTO _res;

  RETURN _res;
END$

-- =========================================================
-- select the drumate profile photo for visitor based on vhost
-- =========================================================
DROP FUNCTION IF EXISTS `drumate_photo_old`$
CREATE FUNCTION `drumate_photo_old`(
    _key varchar(255),
    _vhost varchar(255)
)
RETURNS VARBINARY(16) DETERMINISTIC
BEGIN
  DECLARE _area varchar(30);
  DECLARE _uid VARBINARY(16);
  DECLARE _res VARBINARY(16);

  SELECT id FROM entity WHERE ident=_key OR id=_key INTO _uid;
  SELECT area FROM vhost INNER JOIN entity using(id) WHERE fqdn=_vhost INTO _area;
  IF _area = 'personal' THEN
    SELECT 'private' INTO  _area;
  END IF;

  SELECT photo FROM profile WHERE id=CONCAT(_uid, "@", _area) INTO _res;

  RETURN _res;
END$


-- =========================================================
-- select the drumate profile photo for visitor based on vhost
-- =========================================================
DROP FUNCTION IF EXISTS `drumate_photo`$
CREATE FUNCTION `drumate_photo`(
    _key varchar(255),
    _vhost varchar(255)
)
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
  DECLARE _area varchar(30);
  DECLARE _uid varchar(16);
  DECLARE _res varchar(255);

  SELECT id FROM entity WHERE ident=_key OR id=_key INTO _uid;
  SELECT REPLACE(JSON_EXTRACT(`profile`, '$.avatar'), '"', "") 
    FROM drumate WHERE id=_uid INTO _res;
  RETURN _res;
END$

-- =========================================================
-- select the drumate profile photo for visitor based on vhost
-- =========================================================
DROP FUNCTION IF EXISTS `hub_photo`$
CREATE FUNCTION `hub_photo`(
    _key varchar(255)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _res VARBINARY(16);

  SELECT photo FROM hub_ssv WHERE ident=_key OR id=_key OR vhost=_key INTO _res;

  RETURN _res;
END$

-- =========================================================
-- 
-- =========================================================
-- DROP FUNCTION IF EXISTS `test_var`$
-- CREATE FUNCTION `test_var`(
--     _key varchar(255)
-- )
-- RETURNS VARCHAR(255) DETERMINISTIC
-- BEGIN
--   DECLARE _res VARCHAR(255);

--   SET _res = _key;

--   CASE _key
--       WHEN 'public' THEN 
--          SET _res = -1
--       WHEN 'restricted' THEN
--          SET _res = -2
--       WHEN 'private' THEN 2
--          SET _res = -3
--   END;
--   RETURN _res;
-- END$

-- =========================================================
-- 
-- =========================================================

DROP FUNCTION IF EXISTS `SPLIT_STRING`$
CREATE FUNCTION `SPLIT_STRING`(
  str VARCHAR(255) ,
  delim VARCHAR(12) ,
  pos INT
) RETURNS VARCHAR(255) CHARSET utf8 DETERMINISTIC
BEGIN 
  RETURN
    REPLACE(
      SUBSTRING(
        SUBSTRING_INDEX(str , delim , pos) ,
        CHAR_LENGTH(
          SUBSTRING_INDEX(str , delim , pos - 1)
        ) + 1
      ) ,
      delim , ''
    );
END$


-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `duration_days`$
CREATE FUNCTION `duration_days`(
  expiry_time INT(11)
) RETURNS INTEGER DETERMINISTIC
BEGIN 
  DECLARE _res INTEGER;
  DECLARE _ts INT(11);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT  CASE 
    WHEN expiry_time = 0 THEN  NULL
    WHEN (expiry_time - _ts) < 86400  THEN 0
    WHEN (expiry_time - _ts) > 86400  THEN FLOOR((expiry_time - _ts)/86400)
  END INTO _res;
  RETURN _res;
END$

-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `duration_hours`$
CREATE FUNCTION `duration_hours`(
  expiry_time INT(11)
) RETURNS INTEGER DETERMINISTIC
BEGIN 
  DECLARE _res INTEGER;
  DECLARE _ts INT(11);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT  CASE 
    WHEN expiry_time = 0 THEN  NULL
    WHEN 
    (expiry_time - _ts) > 0  THEN CEIL(MOD((expiry_time - _ts),86400)/3600)  
    WHEN (expiry_time - _ts) > 0  THEN 0
  END INTO _res;
  RETURN _res;
END$



-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `unique_username_next`$
DROP FUNCTION IF EXISTS `unique_username`$
CREATE FUNCTION `unique_username`(
  _username VARCHAR(200),
  _domain_name VARCHAR(500)
) RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count TINYINT(8) DEFAULT 0;
  DECLARE _i TINYINT(6) DEFAULT 0;
  DECLARE _depth TINYINT(6) DEFAULT 0;
  
  SELECT _username INTO _r;
  SELECT count(*) FROM drumate u INNER JOIN(domain d) ON u.domain_id=d.id 
    WHERE username = _r AND (d.name=_domain_name OR d.id=_domain_name) INTO _count;
  IF _username regexp '[\_\-]\([0-9]+\)$' THEN 
    SELECT SUBSTRING_INDEX(_username, '-', -1) INTO _depth;
    SELECT SUBSTRING_INDEX(_username, '-', 1) INTO @base;
    WHILE _depth  < 1000 AND _count <> 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT CONCAT(@base, "-", _depth) INTO _r;
      SELECT count(*) FROM drumate u INNER JOIN(domain d) ON u.domain_id=d.id
      WHERE username = _r AND (d.name=_domain_name OR d.id=_domain_name) INTO _count;
    END WHILE;
  ELSE 
    WHILE _count <> 0 DO
      SELECT count(*) FROM drumate u INNER JOIN(domain d) ON u.domain_id=d.id
        WHERE username = _r AND (d.name=_domain_name OR d.id=_domain_name) INTO _count;
      IF _count >0 THEN 
        SELECT _i + 1 INTO _i;
        SELECT CONCAT(_username, _i) INTO _r;
      END IF;
    END WHILE;
  END IF;
  RETURN _r;
END$
-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `unique_ident`$
CREATE FUNCTION `unique_ident`(
  _ident VARCHAR(200)
) RETURNS VARCHAR(1024) DETERMINISTIC
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
      SELECT count(*) FROM hub WHERE hubname = _r INTO _count;
       SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
    END WHILE;
  ELSE 
    WHILE _count <> 0 DO
      SELECT count(*) FROM hub WHERE hubname = _r INTO _count;
      SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
      IF _count >0 THEN 
        SELECT _i + 1 INTO _i;
        SELECT CONCAT(_ident, _i) INTO _r;
      END IF;
    END WHILE;
  END IF;
  RETURN _r;
END$

-- =========================================================
-- get_vhost, based on @domain_name
-- =========================================================
DROP FUNCTION IF EXISTS `entity_db`$
CREATE FUNCTION `entity_db`(
  _id VARCHAR(160)
)
RETURNS VARCHAR(30) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(30);
  SELECT db_name FROM entity WHERE id=_id INTO _r;
  RETURN _r;
END$


DELIMITER ;
