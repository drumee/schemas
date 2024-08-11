DELIMITER $

-- =========================================================
-- hub_update_visibility
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_update_visibility`$
CREATE PROCEDURE `hub_update_visibility`(
  IN _hub_id        VARCHAR(16),
  IN _visibility    VARCHAR(50)
)
BEGIN
    UPDATE entity SET area = _visibility WHERE id = _hub_id;
    SELECT * FROM entity WHERE id = _hub_id;
END $

-- =========================================================
-- hub_list_by_owner
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_list_by_owner`$
CREATE PROCEDURE `hub_list_by_owner`(
  IN _owner_id    VARCHAR(16)
)
BEGIN
    SELECT h.id, ident, vhost, db_name, home_dir, type, area, status, settings, icon
      FROM hub h JOIN entity e USING(id) WHERE owner_id = _owner_id;
END $

-- =========================================================
-- hub_list
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_list`$
CREATE PROCEDURE `hub_list`()
BEGIN
    SELECT db_name, home_dir FROM entity WHERE type = 'community';
END $


-- =========================================================
-- hub_update_title
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_update_title`$
CREATE PROCEDURE `hub_update_title`(
  IN _hub_id    VARCHAR(16),
  IN _hub_title VARCHAR(200)
)
BEGIN
    UPDATE entity SET headline = _hub_title WHERE id = _hub_id;
    SELECT * FROM entity WHERE id = _hub_id;
END $

-- =========================================================
-- hub_update_name
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_update_name`$
CREATE PROCEDURE `hub_update_name`(
  IN _hub_id    VARCHAR(16),
  IN _name      VARCHAR(80)
)
BEGIN
  UPDATE hub SET `name` = _name, `profile` = JSON_SET(`profile`, "$.name", _name) WHERE id = _hub_id;
  SELECT entity.id, entity.ident, entity.mtime, entity.status, entity.type, entity.area,
  entity.vhost, entity.headline, entity.layout as fallback, entity.home_layout as home,
  entity.layout, entity.db_name, entity.db_host, entity.fs_host, entity.home_dir,
  entity.settings, hub.name, hub.permission, hub.dmail,  hub.profile
  FROM entity INNER JOIN hub USING(id) WHERE entity.id = _hub_id;
END $

-- =========================================================
-- hub_update_settings
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_update_settings`$
-- CREATE PROCEDURE `hub_update_settings`(
--   IN _hub_id    VARCHAR(16),
--   IN _settings  MEDIUMTEXT
-- )
-- BEGIN
--     UPDATE entity SET settings = _settings WHERE id = _hub_id;
--     SELECT * FROM entity WHERE id = _hub_id;
-- END $

-- =========================================================
-- hub_change_settings
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_change_settings`$
CREATE PROCEDURE `hub_change_settings`(
  IN _hub_id    VARCHAR(16),
  IN _name      VARCHAR(100),
  IN _value     VARCHAR(1024)
)
BEGIN
    UPDATE entity SET `settings` = JSON_SET(`settings`, CONCAT("$.", _name), _value) 
      WHERE id = _hub_id;
    SELECT id, settings FROM entity WHERE id = _hub_id;
END $

-- =========================================================
-- hub_change_settings
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_change_profile`$
CREATE PROCEDURE `hub_change_profile`(
  IN _hub_id    VARCHAR(16),
  IN _name      VARCHAR(100),
  IN _value     VARCHAR(1024)
)
BEGIN
    UPDATE entity SET `settings` = JSON_SET(`profile`, CONCAT("$.", _name), _value) 
      WHERE id = _hub_id;
    SELECT id, profile FROM entity WHERE id = _hub_id;
END $


-- =========================================================
-- hub_update_favicon
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_update_favicon`$
CREATE PROCEDURE `hub_update_favicon`(
  IN _hub_id    VARCHAR(16),
  IN _favicon  MEDIUMTEXT
)
BEGIN
    UPDATE entity SET icon = _favicon WHERE id = _hub_id;
    SELECT * FROM entity WHERE id = _hub_id;
END $

-- =========================================================
-- Register
-- =========================================================

DROP PROCEDURE IF EXISTS `hub_register`$
CREATE PROCEDURE `hub_register`(
  IN _ident VARCHAR(80),
  IN _area VARCHAR(16),
  IN _uid  VARCHAR(16),
  IN _profile VARCHAR(16000),
  IN _settings VARCHAR(16000),
  IN _status VARCHAR(16)
)
BEGIN
  DECLARE _db_host VARCHAR(255);
  DECLARE _fs_host VARCHAR(255);
  DECLARE _home_dir VARCHAR(255);
  DECLARE _hid VARCHAR(16);
  DECLARE _now INT(11);
  DECLARE _domain VARCHAR(80);
  DECLARE _db_name VARCHAR(80);
  DECLARE _dmail VARCHAR(500);
  DECLARE _fingerprint VARCHAR(512);

  SELECT uniqueId(), UNIX_TIMESTAMP(), main_domain(), get_dmail(_ident), make_db_name()
    INTO _hid, _now, _domain, _dmail, _db_name;

  SELECT dbhost, fshost, CONCAT(site_root, _hid, '/') FROM settings WHERE build=1
  	 INTO _db_host, _fs_host, _home_dir;
  
  SELECT conf_value FROM sys_conf WHERE conf_key = 'icon' INTO @_icon;

  START TRANSACTION;
    INSERT INTO entity (
      `id`,`ident`,`db_name`,`db_host`,`fs_host`, `home_dir`,
      `vhost`, `settings`, `type`, `area`, icon,
      `status`, `ctime`, `mtime`)
    VALUES (
      _hid, _ident, _db_name, _db_host, _fs_host, _home_dir ,
      yp.get_vhost(_ident), _settings, 'community', _area, @_icon,
      IF(_status IS NULL OR _status='', 'active', _status), _now, _now);

    INSERT INTO hub (`id`, `owner_id`, `origin_id`, `name`, `keywords`, `dmail`, `profile`)
    VALUES (_hid, _uid, _uid, TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(_profile, '$.name')), yp.dmail(_ident))),
    "Key words", _dmail, _profile);


-- Statitics 
    INSERT INTO yp.disk_usage VALUES(null, _hid, 0); 
-- dmail stuffs
-- TO BE DONE FOR HUB
--    CALL mailserver.create_mailbox(_ident, _domain, uniqueId());
    SET @s = CONCAT("CREATE DATABASE `", _db_name, "` CHARACTER SET utf8 COLLATE utf8_general_ci");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  COMMIT;

  SELECT
    entity.id,
    entity.ident,
    entity.mtime,
    entity.status,
    entity.type,
    entity.area,
    entity.vhost,
    entity.headline,
    entity.layout as fallback,
    entity.home_layout as home,
    entity.layout,
    entity.db_name,
    entity.db_host,
    entity.fs_host,
    entity.home_dir,
    entity.settings,
    hub.name,
    hub.owner_id,
    hub.permission,
    hub.dmail,
    hub.photo,
    hub.profile
  FROM entity INNER JOIN hub USING(id) WHERE ident = _ident;
END$

-- =========================================================
-- Register
-- =========================================================


-- =========================================================
-- hub_search
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_search`$
CREATE PROCEDURE `hub_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    _page as `page`,
    entity.id,
    entity.ident,
    `status`,
    `type`,
    dmail,
    vhost,
    area,
    name,
    photo,
    permission,
    entity.mtime,
    entity.ctime,
    home_layout as home,
    layout as fallback,
    headline,
    MATCH(`headline`)
      against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) *10
    + MATCH(`name`, keywords)
      against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) *10
    + IF(MATCH(`ident`)
      against(concat('*', _pattern, '*') IN BOOLEAN MODE), 25, 0) AS score
    FROM hub join entity USING(id) HAVING score > 24
    ORDER BY score DESC LIMIT _offset, _range;
END $


-- =========================================================
-- hub_update
--
-- =========================================================

DROP PROCEDURE IF EXISTS `hub_update`$
CREATE PROCEDURE `hub_update`(
  IN _id VARCHAR(16),
  IN _ident VARCHAR(40),
  IN _name VARCHAR(40),
  IN _headline VARCHAR(255),
  IN _keywords VARCHAR(1024),
  IN _permission TINYINT(4)
)
BEGIN
  DECLARE _type VARCHAR(40);
  DECLARE _cur_ident VARCHAR(40);
  DECLARE _cur_oid VARCHAR(20);

  SELECT ident, area_oid FROM site_csv WHERE id=_id INTO _cur_ident, _cur_oid;

  START TRANSACTION;
    UPDATE entity SET headline=_headline, ident=_ident,
      vhost=yp.get_vhost(_ident), mtime=unix_timestamp() WHERE id=_id;

    UPDATE hub SET keywords=_keywords, name=_name, permission=_permission WHERE id=_id;

    IF _ident != _cur_ident AND _cur_ident !='' THEN
      UPDATE `vhost` SET fqdn=yp.get_vhost(_ident) WHERE fqdn=yp.get_vhost(_cur_ident);
    END IF;
    SELECT * FROM site_view WHERE id=_id;
  COMMIT;
END$


-- =========================================================
-- Disable community
-- =========================================================

DROP PROCEDURE IF EXISTS `hub_freeze`$
CREATE PROCEDURE `hub_freeze`(
   IN _key VARCHAR(80)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _ident VARCHAR(128);

  SELECT id, ident FROM entity_ssv WHERE ident=_key OR id=_key INTO _id, _ident;

  START TRANSACTION;
    UPDATE entity SET status = 'frozen' WHERE  id=_id;
    -- UPDATE mailserver.mailbox SET active = 0 WHERE  local_part=_ident;
    -- UPDATE mailserver.alias SET active = 0 WHERE  address=yp.dmail(_ident);
  COMMIT;

END$


-- =========================================================
-- Disable community
-- =========================================================

DROP PROCEDURE IF EXISTS `hub_has_huber`$
CREATE PROCEDURE `hub_has_huber`(
   IN _hid VARCHAR(16),
   IN _uid VARCHAR(16)
)
BEGIN

  SELECT *  FROM membership_csv WHERE  hid=_hid AND uid=_uid;

END$


-- =========================================================
-- List members belongin to a hub
-- hub_show_hubers
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_show_hubers`$
-- CREATE PROCEDURE `hub_show_hubers`(
--   IN _hid VARCHAR(16),
--   IN _uid VARCHAR(16),
--   IN _page TINYINT(4)
-- )
-- BEGIN
--   DECLARE _ident VARCHAR(255);
--   DECLARE _area VARCHAR(20);
--   DECLARE _range bigint;
--   DECLARE _offset bigint;
--   CALL pageToLimits(_page, _offset, _range);

--   SELECT area FROM entity_ssv WHERE id=_hid INTO _area;

--   IF _area = 'private' THEN
--     SELECT ident FROM hubers_csv WHERE hid=_hid AND id=_uid INTO _ident;
--     IF _ident IS NOT NULL OR _ident!='' THEN
--       SELECT * FROM  hubers_csv WHERE hid=_hid ORDER BY lastname, firstname ASC LIMIT _offset, _range;
--     END IF;
--   ELSE
--     SELECT * FROM  hubers_csv WHERE hid=_hid ORDER BY lastname, firstname ASC LIMIT _offset, _range;
--   END IF;

-- END$



-- =========================================================
-- hub_lookup
-- Sensitives columns (db_host, etc.) MUST NOT BE not selected
-- =========================================================

-- DROP PROCEDURE IF EXISTS `hub_lookup`$
-- CREATE PROCEDURE `hub_lookup`(
--   IN _site VARCHAR(255),
--   IN _visitor VARCHAR(255)
-- )
-- BEGIN
--   DECLARE _type VARCHAR(40);
--   DECLARE _site_id VARCHAR(16);
--   DECLARE _vis_id VARCHAR(16);
--   SET @priv = 0;
--
--   SELECT `type`, id FROM vhost_view WHERE vhost=_site INTO _type, _site_id;
--   SELECT id FROM drumate_csv WHERE ident=_visitor OR id=_visitor OR vhost=_visitor INTO _vis_id;
--
--   IF _type = 'community' THEN
--     SELECT privilege FROM membership where drumate_id=_vis_id and cid=_site_id INTO @priv;
--     SELECT *, @priv AS privilege FROM site_view WHERE id=_site_id;
--   ELSEIF _type = 'drumate' THEN
--     IF _site_id = _vis_id THEN
--       SET @priv = 31; -- = 0b11111
--     END IF;
--     SELECT *, @priv AS privilege FROM drumate_csv WHERE id=_site_id;
--   ELSE
--     SELECT *, @priv AS privilege FROM entity_ssv WHERE id='ffffffffffffffff';
--   END IF;
-- END$



-- =======================================================================
-- Remove user from a hub
-- =======================================================================
DROP PROCEDURE IF EXISTS `hub_remove_huber`$
-- CREATE PROCEDURE `hub_remove_huber`(
--   IN _hid  VARCHAR(16),
--   IN _uid  VARCHAR(16)
-- )
-- BEGIN

--   DECLARE _count INT(8);
--   SELECT COUNT(*) FROM membership WHERE hub_id=_hid  AND privilege >=16
--     INTO _count;
--   IF _count > 1  THEN
--     DELETE FROM membership WHERE hub_id=_hid AND drumate_id=_uid;
--     SELECT *, _count as leader FROM membership_csv WHERE hid=_hid AND uid=_uid;
--   ELSE
--     SELECT _count as leader;
--   END IF;
-- END $

-- =======================================================================
-- set_privilege in the hub
-- =======================================================================
DROP PROCEDURE IF EXISTS `hub_set_privilege`$
-- CREATE PROCEDURE `hub_set_privilege`(
--   IN _hid  VARCHAR(16),
--   IN _uid  VARCHAR(16),
--   IN _priv TINYINT(4)
-- )
-- BEGIN

--   UPDATE membership set privilege=_priv WHERE hub_id=_hid AND drumate_id=_uid;
--   SELECT * FROM membership_csv WHERE hid=_hid AND drumate_id=_uid;

-- END $

-- =======================================================================
-- Remove user from a hub
-- =======================================================================
-- DROP PROCEDURE IF EXISTS `hub_remove_huber`$
-- CREATE PROCEDURE `hub_remove_huber`(
--   IN _hid  VARCHAR(16),
--   IN _uid  VARCHAR(16)
-- )
-- BEGIN
--
--   DELETE FROM membership where cid=_hid AND drumate_id=_uid;
--
-- END $


-- =======================================================================
-- Add user into a hub
-- =======================================================================
DROP PROCEDURE IF EXISTS `OLD_hub_add_huber`$
-- CREATE PROCEDURE `OLD_hub_add_huber`(
--   IN _uid  VARCHAR(16),
--   IN _hid  VARCHAR(16),
--   IN _privilege INT(8)
-- )
-- BEGIN

--   DECLARE _now INT(11);

--   SELECT UNIX_TIMESTAMP() INTO _now ;

-- -- to be romoved : `user_id`, `cid`, `area_id`, `area`, `username`
--   INSERT INTO membership (`id`,`user_id`,`drumate_id`,`privilege`,`cid`,`hub_id`,
--          `area_id`, `area`, `username`, `add_time`, `update_time`)
--   VALUES (concat(_uid, '@', _hid), 'not used', _uid, _privilege, 'not used', _hid,
--          'not used' , 'not used', 'not used', _now, _now);

--   SELECT * FROM hubers_csv WHERE affiliation=concat(_uid, '@', _hid);


-- END $

-- =======================================================================
-- Add user into a hub
-- =======================================================================
DROP PROCEDURE IF EXISTS `hub_add_huber`$
-- CREATE PROCEDURE `hub_add_huber`(
--   IN _uid  VARCHAR(16),
--   IN _hid  VARCHAR(16),
--   IN _privilege INT(8)
-- )
-- BEGIN

--   DECLARE _now INT(11);

--   SELECT UNIX_TIMESTAMP() INTO _now ;

-- -- to be romoved : `user_id`,
--   INSERT INTO membership (`id`, `drumate_id`, `privilege`, `hub_id`, `add_time`, `update_time`)
--   VALUES (concat(_uid, '@', _hid), _uid, _privilege, _hid, _now, _now);

--   SELECT * FROM hubers_csv WHERE affiliation=concat(_uid, '@', _hid);


-- END $


-- =========================================================
-- Get partial profile from entity, based on type attribute
-- System columns (db_host, etc.) are not selected
-- =========================================================

DROP PROCEDURE IF EXISTS `get_hubers_by_perm`$
-- CREATE PROCEDURE `get_hubers_by_perm`(
--   IN _hid VARCHAR(16),
--   IN _privilege INT(8)
-- )
-- BEGIN
--   SELECT * FROM hubers_csv WHERE hid=_hid AND privilege >=_privilege;
-- END$


-- =======================================================================
-- Assign a profile photo
-- =======================================================================
DROP PROCEDURE IF EXISTS `hub_set_photo`$
CREATE PROCEDURE `hub_set_photo`(
  IN _hid VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN

  UPDATE hub SET photo=_nid WHERE id=_hid;
  SELECT *, _nid as nid FROM vhost_csv WHERE id=_hid;
END $



DELIMITER ;

-- #####################
