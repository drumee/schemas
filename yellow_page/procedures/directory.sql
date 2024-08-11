DELIMITER $

-- =========================================================
--
-- DIRECTORY INTERFACE
--
-- =========================================================

--  _____       _   _ _                           _   _             
-- | ____|_ __ | |_(_) |_ _   _     ___  ___  ___| |_(_) ___  _ __  
-- |  _| | '_ \| __| | __| | | |   / __|/ _ \/ __| __| |/ _ \| '_ \ 
-- | |___| | | | |_| | |_| |_| |   \__ \  __/ (__| |_| | (_) | | | |
-- |_____|_| |_|\__|_|\__|\__, |   |___/\___|\___|\__|_|\___/|_| |_|
--                        |___/                                     

DROP PROCEDURE IF EXISTS `entity_touch`$
CREATE PROCEDURE `entity_touch`(
  IN _key VARBINARY(128)
)
BEGIN
  UPDATE entity SET mtime=UNIX_TIMESTAMP() WHERE id=_key OR ident=_key;
  SELECT id, ident, mtime, settings FROM entity WHERE id=_key OR ident=_key;
END$


-- =========================================================
-- lookup_dmail
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_dmail`$
CREATE PROCEDURE `lookup_dmail`(
  IN _key VARCHAR(255)
)
BEGIN
  SELECT COUNT(*) FROM postfix.mailbox WHERE local_part=_key;
END$


-- =========================================================
-- presignon
-- =========================================================

DROP PROCEDURE IF EXISTS `presignon`$
CREATE PROCEDURE `presignon`(
  IN _email VARCHAR(500),
  IN _referer VARCHAR(500)
)
BEGIN
  INSERT INTO preregister VALUES(_email, _referer, UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE referer=_referer, ctime=UNIX_TIMESTAMP();
  SELECT * FROM preregister WHERE email=_email;
END$



DROP PROCEDURE IF EXISTS `lookup_area`$
CREATE PROCEDURE `lookup_area`(
  IN _id VARBINARY(16)
)
BEGIN
  SELECT * FROM entity_ssv WHERE area_id=_id GROUP BY area_id=_id;
END$





-- =========================================================
-- hub_header
-- =========================================================
DROP PROCEDURE IF EXISTS `get_hub_header`$
DROP PROCEDURE IF EXISTS `get_hub_header_next`$
CREATE PROCEDURE `get_hub_header`(
  IN _vhost    VARCHAR(255),
  IN _lang      VARCHAR(16)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _count TINYINT(4);
  DECLARE _ident VARCHAR(200);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _icon VARCHAR(1024);

  -- IF _vhost NOT REGEXP '^(.+)\\.(.+)' THEN
  --   SELECT concat(ident, '.drumee.com') 
  --     FROM entity WHERE ident=_vhost OR id=_vhost 
  --     INTO _vhost;
  -- END IF;

  SELECT vhost(_vhost) INTO _vhost;

  SELECT id FROM vhost where fqdn=_vhost INTO _id;
  IF _id IS NULL OR _id="" THEN
    SELECT id FROM entity where ident=_vhost OR id=_vhost INTO _id;
  END IF;

  SELECT id FROM header WHERE id=_id LIMIT 1 INTO _hub_id;

  SELECT ident, icon FROM entity WHERE id=_id INTO _ident, _icon;

  IF _hub_id IS NULL OR _hub_id="" THEN
    SELECT id FROM entity WHERE ident='home' INTO _id;
    SELECT count(*) FROM header WHERE id=_id and `language`=_lang INTO _count;
    IF _count THEN 
      SELECT 
        title,
        keywords,
        IFNULL(icon, _icon) icon,
        `language`,
        _vhost vhsot, 
        _ident ident
      FROM header WHERE id=_id and `language`=_lang;
    ELSE
      SELECT 
        title,
        keywords,
        IFNULL(icon, _icon) icon,
        `language`,
        _vhost vhsot, 
        _ident ident
      FROM header WHERE id=_id and `language`='*';
    END IF;
  ELSE
    SELECT count(*) FROM header WHERE id=_hub_id and `language`=_lang INTO _count;
    IF _count THEN 
      SELECT 
        title,
        keywords,
        IFNULL(icon, _icon) icon,
        `language`,
        _vhost vhsot, 
        _ident ident
      FROM header WHERE id=_hub_id and `language`=_lang;
    ELSE 
      SELECT
        title,
        keywords,
        IFNULL(icon, _icon) icon,
        `language`,
        _vhost vhsot, 
        _ident ident
      FROM header WHERE id=_hub_id and `language`='*';
    END IF;
  END IF;
END $


-- =========================================================
-- yp_change_hub_status
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_change_hub_status`$
CREATE PROCEDURE `yp_change_hub_status`(
  IN _user_id   VARBINARY(16),
  IN _key       VARCHAR(255),
  IN _perm      INT(4),
  IN _status    VARCHAR(100)
)
BEGIN
  DECLARE _db_name VARCHAR(20);
  SET @p=0;
  SELECT `db_name` FROM entity WHERE ident=_key OR id=_key INTO _db_name;
  SET @s = CONCAT("SELECT privilege&", _perm, " FROM `", 
    _db_name, "`.`huber` WHERE id='", _user_id, "' INTO @p");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  IF @p > 0 THEN
    UPDATE entity e SET status = _status WHERE db_name = _db_name;
  END IF;
  SELECT @p AS valid_user;
  
END $


-- =========================================================
-- Set mailbow status (active = 0 or 1)
-- =========================================================

DROP PROCEDURE IF EXISTS `set_mailbox`$
CREATE PROCEDURE `set_mailbox`(
   IN dmail VARCHAR(255),
   IN act INT
)
BEGIN
  START TRANSACTION;
    UPDATE postfix.mailbox SET active = act WHERE  username=dmail;
    UPDATE postfix.alias SET active = act WHERE  address=dmail;
  COMMIT;
END$


-- =========================================================
-- lookup_user
-- lookup_user
-- =========================================================


--  _   _ ____  _____ ____     ____  _____ ____ _____ ___ ___  _   _ 
-- | | | / ___|| ____|  _ \   / ___|| ____/ ___|_   _|_ _/ _ \| \ | |
-- | | | \___ \|  _| | |_) |  \___ \|  _|| |     | |  | | | | |  \| |
-- | |_| |___) | |___|  _ <    ___) | |__| |___  | |  | | |_| | |\  |
--  \___/|____/|_____|_| \_\  |____/|_____\____| |_| |___\___/|_| \_|
                                                                  

-- =========================================================
-- get_user MOVED TO directory
-- =========================================================




-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `check_password`$
CREATE PROCEDURE `check_password`(
  IN _key VARCHAR(128),
  IN _pw VARCHAR(128)
)
BEGIN
  SELECT
    entity.id,
    entity.ident,
    db_name,
    db_host,
    fs_host,
    vhost,
    home_dir,
    type,
    status,
    email,
    lastname,
    mtime,
    ctime,
    fingerprint,
    fullname,
    headline  
  FROM entity JOIN drumate USING(id)
  WHERE fingerprint=sha2(_pw, 512) AND (ident=_key OR id=_key OR email=_key);
END$

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `check_password_next`$
CREATE PROCEDURE `check_password_next`(
  IN _key VARCHAR(128),
  IN _pw VARCHAR(128)
)
BEGIN

  SELECT
    entity.id,
    entity.ident,
    db_name,
    db_host,
    fs_host,
    vhost,
    home_dir,
    type,
    status,
    email,
    firstname,
    lastname,
    area,
    mtime,
    ctime,
    fingerprint,
    fullname
  FROM entity JOIN drumate USING(id)
  WHERE fingerprint=sha2(_pw, 512) AND (ident=_key OR id=_key OR email=_key);

END$



-- =========================================================
-- Reset password on lost
-- WILL BE OBSOLETED
-- =========================================================

DROP PROCEDURE IF EXISTS `reset_password`$
CREATE PROCEDURE `reset_password`(
  IN _vhost VARCHAR(255),
  IN _key VARCHAR(255),
  IN _actime INT(11),
  IN _pw VARCHAR(160)
)
BEGIN
  DECLARE _check VARCHAR(160);
  DECLARE _id VARCHAR(16);
  START TRANSACTION;
    SELECT id FROM entity WHERE vhost=_vhost INTO _id;
    UPDATE drumate SET fingerprint=sha2(_pw, 512) WHERE id=_id AND activation_key=_key AND activation_time=_actime;
    SELECT fingerprint FROM drumate WHERE id=_id AND activation_key=_key AND activation_time=_actime INTO _check;
    IF _check = '' OR _check is NULL THEN
      SELECT NULL;
    ELSE
      UPDATE drumate SET activation_key='', activation_time=NULL WHERE id=_id;
      SELECT _id AS id, _vhost AS vhost;
    END IF;
  COMMIT;
END$


-- =========================================================
-- Get the most intimate photo between two drumates
-- =========================================================
DROP PROCEDURE IF EXISTS `lookup_drumates`$
CREATE PROCEDURE `lookup_drumates`(
  IN _key VARCHAR(255),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    _page as `page`,
    d.id,
    e.ident,
    d.firstname,
    d.lastname,
    d.remit,
    email
  FROM entity e INNER JOIN (yp.drumate d) USING(id) 
    WHERE ident 
    LIKE CONCAT(_key, "%") OR 
    email LIKE CONCAT(_key, "%") OR 
    d.firstname LIKE CONCAT(_key, "%") OR 
    d.lastname LIKE CONCAT(_key, "%") ORDER BY d.lastname DESC LIMIT _offset, _range;
END$

-- =========================================================
-- Get the most intimate photo between two drumates
-- =========================================================
-- WILL BE DEPRECATED 
DROP PROCEDURE IF EXISTS `get_innest_photo`$
CREATE PROCEDURE `get_innest_photo`(
   IN id1 VARBINARY(16),
   IN id2 VARBINARY(16)
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _index INT DEFAULT 0;
  DECLARE _best INT DEFAULT 0;
  DECLARE _level VARCHAR(40);
  DECLARE photo VARCHAR(40);
  DECLARE _field VARCHAR(40);
  DECLARE _areas CURSOR FOR SELECT if(count(*)>1, area, 'external') as c_area
    FROM membership
    WHERE drumate_id=id1 OR drumate_id=id2 GROUP BY area, hub_id HAVING c_area!='external';
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _done = 1;

  OPEN _areas;

  REPEAT
    FETCH _areas INTO _level;
       SELECT CASE _level
           WHEN 'public' THEN 0
           WHEN 'restricted' THEN 1
           WHEN 'private' THEN 2
       END into _index;
       IF _index > _best THEN
           SET _best = _index;
       END IF;
  UNTIL _done END REPEAT;
  SELECT CASE _best
      WHEN 0 THEN 'photo_pub'
      WHEN 1 THEN 'photo_res'
      WHEN 2 THEN 'photo_prv'
  END into photo;

  CLOSE _areas;
  SET @s = CONCAT("SELECT ",photo," AS photo FROM drumate_view WHERE id=", quote(id2));
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END$





-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `ident_exists`$
CREATE PROCEDURE `ident_exists`(
  IN _key VARCHAR(128)
)
BEGIN
  
  SELECT id, ident, status FROM entity WHERE ident=_key 
  UNION
  SELECT id ,ident, 'active' status FROM  organisation WHERE ident=_key;
END$


DROP PROCEDURE IF EXISTS `org_ident_exists`$
CREATE PROCEDURE `org_ident_exists`(
  IN _key VARCHAR(128)
)
BEGIN
  
  SELECT * FROM 
  (SELECT d.id, d.username ident,'active' status FROM drumate d INNER JOIN privilege p ON p.uid =d.id AND p.domain_id =1  WHERE username=_key  LIMIT 1) a 
  UNION
  SELECT id ,ident, 'active' status FROM  organisation WHERE ident=_key LIMIT 1;
END$


-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `email_exists`$
CREATE PROCEDURE `email_exists`(
  IN _key VARCHAR(128)
)
BEGIN

  SELECT email, id FROM drumate WHERE email=_key;

END$

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `dmail_exists`$
CREATE PROCEDURE `dmail_exists`(
  IN _key VARCHAR(128)
)
BEGIN

  SELECT email, username FROM mailserver.users WHERE email=_key;

END$

-- =========================================================
--
-- =========================================================
-- DROP PROCEDURE IF EXISTS `ident_exists`$
-- CREATE PROCEDURE `ident_exists`(
--   IN _key VARCHAR(128)
-- )
-- BEGIN

--   SELECT id, ident, status FROM entity WHERE ident=_key;

-- END$




-- =========================================================
-- get_finger_print
-- =========================================================

DROP PROCEDURE IF EXISTS `get_finger_print`$
CREATE PROCEDURE `get_finger_print`(
  IN _key VARCHAR(255) )
BEGIN
  SELECT fingerprint FROM drumate_view WHERE id=_key OR email=_key OR ident=_key ;
END$

-- =========================================================
-- set finger print
-- =========================================================
DROP PROCEDURE IF EXISTS `set_finger_print`$
CREATE PROCEDURE `set_finger_print`(
  IN _ident VARCHAR(100),
  IN _fp VARCHAR(128)
)
BEGIN
  DECLARE _id VARBINARY(16);
  SELECT id FROM entity WHERE ident=_ident INTO _id;
  UPDATE drumate SET fingerprint=_fp where id=_id;
END$

-- =========================================================
-- get_activation_key
-- =========================================================

DROP PROCEDURE IF EXISTS `set_activation_key`$
CREATE PROCEDURE `set_activation_key`(
  IN _uid VARBINARY(16)
)
BEGIN
  DECLARE _key VARCHAR(60);

  SELECT sha2(uuid(),224) INTO _KEY;
  UPDATE drumate SET activation_key=_key, activation_time=UNIX_TIMESTAMP() WHERE id=_uid;
  SELECT _key AS `key`;
END$

-- =========================================================
-- update_ident
-- =========================================================
DROP PROCEDURE IF EXISTS `update_ident`$
CREATE PROCEDURE `update_ident`(
  IN _id              VARBINARY(16),
  IN _new_ident       VARCHAR(60)
)
BEGIN
  DECLARE _old_ident VARCHAR(60);
  DECLARE _type VARCHAR(40);
  DECLARE _domain VARCHAR(80);
  -- SELECT main_domain() INTO _domain;
  SELECT d.name FROM entity e INNER JOIN domain d on e.dom_id=d.id 
    WHERE e.id = _id INTO _domain;
  SELECT ident, `type` FROM entity WHERE id = _id INTO _old_ident, _type;
  START TRANSACTION;
    UPDATE entity SET ident=_new_ident, vhost=CONCAT(_new_ident, '.', _domain) WHERE ident=_old_ident;
    -- UPDATE mailserver.users SET username=_new_ident, email=CONCAT(_new_ident, '@', _domain) WHERE username=_old_ident;
    UPDATE vhost SET fqdn=CONCAT(_new_ident, '.', _domain) WHERE fqdn=CONCAT(_old_ident, '.', _domain);
    -- UPDATE vhost SET fqdn=CONCAT(_new_ident, '.drumee.net') WHERE fqdn=CONCAT(_old_ident, '.drumee.net');
  COMMIT;
  IF _type = "community" or _type = "hub" THEN
    SELECT entity.id, entity.ident, entity.mtime, entity.status, entity.type, entity.area,
    entity.vhost, entity.headline, entity.layout as fallback, entity.home_layout as home,
    entity.layout, entity.db_name, entity.db_host, entity.fs_host, entity.home_dir,
    entity.settings, hub.name, hub.permission, hub.dmail, hub.photo, hub.profile
    FROM entity INNER JOIN hub USING(id) WHERE entity.id = _id;
  ELSEIF _type = "drumate" THEN
    SELECT * FROM drumate_csv WHERE id=_id;
  END IF;
END$



-- =========================================================
-- add_alias
-- =========================================================
DROP PROCEDURE IF EXISTS `add_alias`$
CREATE PROCEDURE `add_alias`(
  IN _ident VARCHAR(80),
  IN _alias VARCHAR(512)
)
BEGIN
  INSERT INTO alias VALUES (_ident, _alias, 'user', SUBSTRING_INDEX(_alias, '.', -2))
  ON DUPLICATE KEY UPDATE vhost=_alias;
END$


-- =========================================================
-- Get online status of the user
-- =========================================================

DROP PROCEDURE IF EXISTS `online_status`$
CREATE PROCEDURE `online_status`(
  IN _key VARCHAR(255)
)
BEGIN

  SELECT * FROM drumate_view WHERE ident=_key OR id=_key OR email=_key;

END$


-- =======================================================================
-- set the layout as the homepage one
-- =======================================================================
DROP PROCEDURE IF EXISTS `set_home_layout`$
CREATE PROCEDURE `set_home_layout`(
  IN _vhost     VARCHAR(512),
  IN _hash_tag  VARCHAR(512)
)
BEGIN

  DECLARE _hid VARBINARY(16);
  SELECT id FROM vhost WHERE fqdn=_vhost INTO _hid;
  UPDATE entity set home_layout=_hash_tag where id=_hid;
  SELECT * FROM entity_csv WHERE id=_hid;

END $

-- =======================================================================
-- set the layout as the homepage one
-- =======================================================================
DROP PROCEDURE IF EXISTS `set_home_layout_2`$
-- CREATE PROCEDURE `set_home_layout_2`(
--   IN _vhost     VARCHAR(512),
--   IN _content   BLOB,
--   IN _hash_tag  VARCHAR(512)
-- )
-- BEGIN

--   DECLARE _hid VARBINARY(16);
--   SELECT id FROM vhost WHERE fqdn=_vhost INTO _hid;
--   UPDATE entity set home_layout=_hash_tag, overview=_content where id=_hid;
--   SELECT * FROM entity_csv WHERE id=_hid;

-- END $


-- =======================================================================
--
-- =======================================================================
DROP PROCEDURE IF EXISTS `get_settings`$
CREATE PROCEDURE `get_settings`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARBINARY(16);
  IF _key REGEXP '^(.+)\\.(.+)' THEN
    SELECT id FROM `vhost` WHERE fqdn=_key INTO _id;
  ELSE
    SELECT id FROM `entity` WHERE id=_key OR ident=_key INTO _id;
  END IF;
  SELECT settings FROM entity WHERE id=_id;
END$



DELIMITER ;

/*
DROP PROCEDURE IF EXISTS `__get_entity`;
DROP PROCEDURE IF EXISTS `lookup_admin`;
DROP PROCEDURE IF EXISTS `common_communities`;
DROP PROCEDURE IF EXISTS `get_profile`;
DROP PROCEDURE IF EXISTS `touch_community`;
DROP PROCEDURE IF EXISTS `admin_list_hubers`;
DROP PROCEDURE IF EXISTS `get_hub_test`;
DROP PROCEDURE IF EXISTS `get_hub_old`;


*/


-- #####################
/*
DEPRECATED
 ____                                _           _ 
|  _ \  ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |
| | | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |
| |_| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |
|____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|
           |_|                                     

-- =========================================================
-- get_privilege
-- =========================================================
DROP PROCEDURE IF EXISTS `get_privilege`$
CREATE PROCEDURE `get_privilege`(
  IN _hid VARCHAR(16),
  IN _uid VARCHAR(80)
)
BEGIN
  SELECT * FROM membership WHERE hub_id=_hid AND drumate_id=_uid;
END$


DROP PROCEDURE IF EXISTS `get_hub`$
CREATE PROCEDURE `get_hub`(
  IN _vhost VARCHAR(255),
  IN _visitor VARCHAR(255)
)
BEGIN
  DECLARE _hid VARBINARY(16);
  DECLARE _hub_db VARCHAR(40);
  DECLARE _drumate_db VARCHAR(40);
  DECLARE _uid VARBINARY(16);
  DECLARE _area VARCHAR(40);
  DECLARE _host_ident VARCHAR(100);
  DECLARE _priv TINYINT(1);
  DECLARE _hubers INT(8);
  DECLARE _pages INT(8);
  

  -- When id or ident is used as vhost, find the vhost
  IF _vhost NOT REGEXP '^(.+)\\.(.+)' THEN
     SELECT concat(ident, '.drumee.com') FROM entity WHERE ident=_vhost OR id=_vhost INTO _vhost;
  END IF;

  SELECT id, db_name, area FROM vhost INNER JOIN entity using(id) WHERE fqdn=_vhost
     INTO _hid, _hub_db, _area;

  SELECT id FROM entity WHERE ident=_visitor OR id=_visitor INTO _uid;


  SET _priv = 0;
  -- if hub doesn't exist use home as default
  IF _hid = '' OR _hid IS NULL THEN
     SET _priv = -2;
     SELECT id, db_name FROM entity WHERE ident = 'home' INTO _hid, _hub_db;
  ELSEIF _uid = 'ffffffffffffffff' THEN
    IF _area = 'public' THEN
      SET _priv = -1;
    END IF;
--     SELECT id, db_name FROM entity WHERE ident = 'home' INTO _hid, _hub_db;
  END IF;

  SET @priv = 1;
  SET @s =CONCAT(
    'SELECT `', _hub_db, '`.user_permission(', quote(_uid), ", '*') INTO @priv;");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @_members = 1;
  IF _area != 'personal' THEN
    SET @s =CONCAT(
      'SELECT count(*) FROM `', _hub_db, '`.permission INTO @_members;');
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  SET @_pages = 0;
  SET @s =CONCAT('SELECT count(*) FROM  `', _hub_db, '`.`block` INTO @_pages');
  PREPARE stmt FROM @s;
  EXECUTE stmt;


  SELECT IF(_priv<0, _priv, @priv) INTO _priv;

  IF _area = 'personal' THEN
    SELECT
      entity.id,
      entity.id as oid,
      ident,
      vhost,
      db_name,
      db_host,
      fs_host,
      home_dir,
      home_layout as home,
      `type`,
      area,
      default_lang,
      headline,
      status,
      ctime,
      mtime,
      layout,
      @_pages as pages,
      @_members as members,
      `space`
      keywords,
      homepage,
      menu,
      icon,
      settings,
      _priv AS privilege,
      entity.id AS owner_id,
      size as disk_usage,
      "" AS `name`
    FROM entity INNER JOIN (drumate, disk_usage) ON 
      hub_id=entity.id AND drumate.id = entity.id  WHERE entity.id=_hid;
  ELSE
    SELECT
      entity.id,
      entity.id as oid,
      ident,
      vhost,
      db_name,
      db_host,
      fs_host,
      home_dir,
      home_layout as home,
      `type`,
      area,
      default_lang,
      headline,
      status,
      ctime,
      mtime,
      layout,
      `space`,
      @_pages as pages,
      @_members as members,
      keywords,
      homepage,
      menu,
      icon,
      settings,
      _priv AS privilege,
      owner_id,
      size as disk_usage, 
      `name`
    FROM entity INNER JOIN (hub, disk_usage) ON 
      hub_id=entity.id AND hub.id = entity.id WHERE entity.id=_hid;
  END IF;
  SET @priv = 0;
  SET @hubers = 0;
END$

-- DROP PROCEDURE IF EXISTS `get_hub`$
-- CREATE PROCEDURE `get_hub`(
--   IN _vhost VARCHAR(255),
--   IN _visitor VARCHAR(255)
-- )
-- BEGIN
--   DECLARE _hid VARBINARY(16);
--   DECLARE _hub_db VARCHAR(40);
--   DECLARE _drumate_db VARCHAR(40);
--   DECLARE _uid VARBINARY(16);
--   DECLARE _area VARCHAR(40);
--   DECLARE _host_ident VARCHAR(100);
--   DECLARE _priv TINYINT(1);
--   DECLARE _hubers INT(8);
--
--
--   -- When id or ident is used as vhost, find the vhost
--   IF _vhost NOT REGEXP '^(.+)\\.(.+)' THEN
--      SELECT concat(ident, '.drumee.com') FROM entity WHERE ident=_vhost OR id=_vhost INTO _vhost;
--   END IF;
--
--   SELECT id, db_name, area FROM vhost INNER JOIN entity using(id) WHERE fqdn=_vhost
--      INTO _hid, _hub_db, _area;
--
--   SELECT id FROM entity WHERE ident=_visitor OR id=_visitor INTO _uid;
--
--   SET _priv = 0;
--   -- if hub doesn't exist use home as default
--   IF _hid = '' OR _hid IS NULL THEN
--      SET _priv = -2;
--      SELECT id, db_name FROM entity WHERE ident = 'home' INTO _hid, _hub_db;
--   END IF;
--
--
--   SET @s =CONCAT('CALL `', _hub_db, '`.get_privilege(', quote(_uid), ',', quote(_area), ', @priv, @hubers)');
--   PREPARE stmt FROM @s;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
--
--   SELECT IF(_priv=-2, _priv, @priv) INTO _priv;
--   SELECT *, id as oid, home_layout as home, _priv AS  privilege, @hubers as members FROM entity WHERE id=_hid;
--   SET @priv = 0;
--   SET @hubers = 0;
--
-- END$


-- =========================================================
-- get_hub
-- Privilege values :
-- (-2) ==> Hub not found
-- (-1) ==> Anonymous visitor -> require login
-- ( 0) ==> Hub not allowed
-- ( 1) ==> Public access
-- (>1) => Drumate privilege inside the hub
-- =========================================================


-- =========================================================
-- Updates an entity status
-- =========================================================
-- DROP PROCEDURE IF EXISTS `yp_change_hub_status`$
-- CREATE PROCEDURE `yp_change_hub_status`(
--   IN _user_id   VARBINARY(16),
--   IN _key       VARCHAR(255),
--   IN _status    VARCHAR(100)
-- )
-- BEGIN
--   DECLARE _valid_user INT(4) DEFAULT 0;
--   SELECT EXISTS(SELECT e.id FROM entity e JOIN hub h ON h.id=e.id AND owner_id = _user_id WHERE e.id = _key OR ident = _key) INTO _valid_user;
--   IF _valid_user = 0 THEN
--     SELECT 0 AS valid_user;
--   ELSE
--     UPDATE entity e JOIN hub h ON h.id=e.id AND owner_id = _user_id SET status = _status WHERE e.id = _key OR ident = _key;
--     SELECT e.id, ident, status, 1 AS valid_user FROM entity e JOIN hub h ON h.id=e.id AND owner_id = _user_id WHERE e.id = _key OR ident = _key;
--   END IF;
-- END $


-- =========================================================
-- Get complete profile from entity, based on type attribute
-- =========================================================

CREATE PROCEDURE `__get_entity`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _type VARCHAR(40);

  SELECT `type` FROM entity WHERE ident=_key OR id=_key INTO _type;

  IF _type = 'community' OR _type = 'hub' OR _type = 'site' THEN
    SELECT * FROM hub_ssv WHERE ident=_key OR id=_key;
  ELSEIF _type = 'drumate' THEN
    SELECT * FROM drumate_ssv WHERE ident=_key OR id=_key OR email=_key;
  ELSE
    SELECT * FROM entity_csv WHERE id='ffffffffffffffff';
  END IF;
END$


-- =========================================================
-- Get common communities to two users
-- =========================================================

DROP PROCEDURE IF EXISTS `common_communities`$
CREATE PROCEDURE `common_communities`(
   IN id1 VARBINARY(16),
   IN id2 VARBINARY(16)
)
BEGIN

  SELECT if(count(*)>1, area, 'external') as c_area, cname, description, photo
    FROM membership
    LEFT JOIN hub ON hub_id=hub.id
    WHERE drumate_id=id1 OR drumate_id=id2 GROUP BY hub_id HAVING c_area!='external';

END$

-- =========================================================
-- lookup_admin
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_admin`$
CREATE PROCEDURE `lookup_admin`(
  IN _key VARCHAR(100),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  IF _key IS NULL OR _key = '' THEN
    SELECT * FROM drumate_csv WHERE (remit&7)>0
      ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT * FROM drumate_csv
      WHERE (id=_key OR ident=_key) AND (remit&7)>0
      ORDER BY ctime DESC LIMIT _offset, _range;
  END IF;

END$

-- =========================================================
-- Get complete profile from entity, based on type attribute
-- =========================================================

DROP PROCEDURE IF EXISTS `get_profile`$
CREATE PROCEDURE `get_profile`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _type VARCHAR(40);

  SELECT `type` FROM entity WHERE ident=_key OR id=_key INTO _type;

  IF _type = 'community' THEN
    SELECT * FROM hub_ssv WHERE ident=_key OR id=_key;
  ELSEIF _type = 'drumate' THEN
    SELECT * FROM drumate_ssv WHERE ident=_key OR id=_key OR email=_key;
  ELSE
    SELECT * FROM entity_csv WHERE id='ffffffffffffffff';
  END IF;
END$

-- =========================================================
-- Update community modification time, to keep track of
-- latest activities
-- =========================================================

DROP PROCEDURE IF EXISTS `touch_community`$
CREATE PROCEDURE `touch_community`(
  IN cid VARBINARY(16)
)
BEGIN

  UPDATE community SET mtime=UNIX_TIMESTAMP() WHERE id=cid;

END$



-- =========================================================
-- List members belongin to a hub
-- =========================================================

CREATE PROCEDURE `admin_list_hubers`(
  IN _cid VARBINARY(16)
)
BEGIN

  SELECT * FROM  membership_csv WHERE cid=_cid;

END$

-- =========================================================
-- Check membership of the specified user
-- =========================================================

DROP PROCEDURE IF EXISTS `is_member`$
CREATE PROCEDURE `is_member`(
  IN _cid VARBINARY(16),
  IN _uid VARBINARY(16)
)
BEGIN

  SELECT drumate_id, cid FROM membership WHERE drumate_id=_uid AND cid=_cid GROUP BY cid;

END$




-- =========================================================
-- find
-- =========================================================

DROP PROCEDURE IF EXISTS `find`$
CREATE PROCEDURE `find`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARCHAR(255);
  DECLARE _type VARCHAR(40);
  SELECT id, `type` FROM entity WHERE ident = _key OR id = _key OR vhost = _key OR `alias` = _key
  INTO _id, _type;
  IF _type = 'drumate' THEN
    SELECT * FROM user_csv WHERE id=_id;
  ELSE
    SELECT * FROM site_csv WHERE id=_id;
  END IF;

END$


-- =======================================================================
-- Register signon request
-- =======================================================================
DROP PROCEDURE IF EXISTS `register`$
CREATE PROCEDURE `register`(
  IN _firstname VARCHAR(255),
  IN _lastname VARCHAR(255),
  IN _email VARCHAR(500),
  IN _ident VARCHAR(80),
  IN _ip VARCHAR(40),
  IN _referer VARCHAR(500)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _key VARCHAR(255);

  SELECT UNIX_TIMESTAMP() into _now;
  SELECT sha2(uuid(),224) INTO _key;

  DELETE FROM signon WHERE email=_email;
  INSERT INTO
    signon VALUES(_firstname, _lastname, _email, _ident, _key, _ip, _referer, _now)
      ON DUPLICATE KEY UPDATE act_key=_key, tstamp=_now, firstname=_firstname,
         lastname=_lastname, email=_email, ident=_ident;

  SELECT * FROM signon WHERE `act_key` = _key;
END$

-- =======================================================================
-- Register signon request
-- =======================================================================
DROP PROCEDURE IF EXISTS `get_registered`$
CREATE PROCEDURE `get_registered`(
  IN _key VARCHAR(255)
)
BEGIN

  SELECT *, 'drumate' as `type` FROM signon WHERE `act_key` = _key;
END$



-- =========================================================
-- list_spaces
-- =========================================================

DROP PROCEDURE IF EXISTS `list_spaces`$
CREATE PROCEDURE `list_spaces`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * FROM spaces_csv ORDER BY mtime DESC LIMIT _offset, _range;
END$

-- =========================================================
-- list_entities
-- =========================================================

DROP PROCEDURE IF EXISTS `list_entities`$
CREATE PROCEDURE `list_entities`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * FROM entity_csv ORDER BY mtime DESC LIMIT _offset, _range;
END$



-- =========================================================
-- list_groups
-- =========================================================

DROP PROCEDURE IF EXISTS `list_hubs`$
CREATE PROCEDURE `list_hubs`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * FROM site_csv ORDER BY mtime DESC LIMIT _offset, _range;
END$

-- =========================================================
-- list_managed_hubs
-- =========================================================

DROP PROCEDURE IF EXISTS `list_managed_hubs`$
CREATE PROCEDURE `list_managed_hubs`(
  IN _manager VARCHAR(255),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * FROM membership_csv WHERE username=_manager AND privilege & 0x10 > 0 AND id is NOT NULL
  ORDER BY mtime DESC LIMIT _offset, _range;
END$

-- =========================================================
-- list_managed_hubs
-- =========================================================

DROP PROCEDURE IF EXISTS `check_privilege`$
CREATE PROCEDURE `check_privilege`(
  IN _username VARCHAR(255),
  IN _cid VARBINARY(16),
  IN _privilege TINYINT(4)
)
BEGIN
  SELECT * FROM membership_csv WHERE username=_username AND cid=_cid AND privilege & _privilege > 0 LIMIT 1;
END$

-- =========================================================
-- lookup_area
-- =========================================================

-- =========================================================
-- get_visitor
-- =========================================================

-- DROP PROCEDURE IF EXISTS `get_visitor_old`$
-- CREATE PROCEDURE `get_visitor_old`(
--   IN _key VARCHAR(255)
-- )
-- BEGIN
--   DECLARE _id VARBINARY(16);

--   SELECT id FROM entity  WHERE ident=_key OR id=_key INTO _id;
--   IF _id IS NULL OR _id = '' THEN
--     SET _id = 'ffffffffffffffff';
--   END IF;
--   SELECT
--     entity.id,
--     entity.id as oid,
--     entity.ident,
--     remit,
--     mtime,
--     ctime,
--     status,
--     profile,
--     quota,
--     concat(firstname, ' ', lastname) as fullname,
--     if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online
--     FROM entity INNER JOIN (drumate) USING(id) WHERE id=_id;
-- END$

-- =========================================================
-- get_visitor_current
-- =========================================================
DROP PROCEDURE IF EXISTS `get_visitor_current`$
CREATE PROCEDURE `get_visitor_current`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _avatar VARCHAR(16);
  DECLARE _disk_usage float(16);

  SELECT id FROM entity  WHERE ident=_key OR id=_key INTO _id;

  SELECT sum(e.space) FROM hub h LEFT JOIN entity e USING(id) 
    WHERE e.id=_id or h.owner_id = _id INTO _disk_usage;
  
  IF _id IS NULL OR _id = '' THEN
    SET _id = 'ffffffffffffffff';
  END IF;
  SELECT photo FROM `profile` WHERE drumate_id=_id and area='public' INTO _avatar;
  SELECT
    entity.id,
    entity.id as oid,
    entity.ident,
    remit,
    mtime,
    ctime,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lang')), '')) AS lang,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), _avatar)) AS avatar,
    status,
    profile,
    settings,
    quota,
    IFNULL(unverified_email,'') AS unverified_email,
    concat(firstname, ' ', lastname) as fullname,
    if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online
    FROM entity INNER JOIN (drumate) USING(id) WHERE id=_id;
END$

-- =========================================================
-- get_drumate
-- =========================================================

DROP PROCEDURE IF EXISTS `get_drumate`$
CREATE PROCEDURE `get_drumate`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARBINARY(16);

  SELECT id FROM entity  WHERE ident=_key OR id=_key INTO _id;
  IF _id IS NULL OR _id = '' THEN
    SET _id = 'ffffffffffffffff';
  END IF;

  SELECT * FROM drumate_view_new  WHERE id=_id;
END$



-- =======================================================================
-- list all spaces the specified user belong to
-- =======================================================================
DROP PROCEDURE IF EXISTS `set_entity_photo`$
CREATE PROCEDURE `set_entity_photo`(
  IN _key VARCHAR(255),
  IN _nid VARBINARY(16),
  IN _field VARBINARY(255)
)
BEGIN

  DECLARE _type VARCHAR(40);
  DECLARE _id VARBINARY(16);

  SELECT `type`, id FROM entity WHERE ident=_key OR id=_key INTO _type, _id;

  IF _type = 'community' THEN
    UPDATE hub SET photo=_nid WHERE id=_id;
    SELECT _nid as nid, 'community' as `type`;
  ELSEIF _type = 'drumate' THEN
    SET @s = CONCAT("UPDATE drumate SET ", _field, "=", quote(_nid), " WHERE id=", quote(_id));
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT _nid as nid, 'drumate' as `type`;
  ELSE
    SELECT NULL;
  END IF;

END $


-- =========================================================
-- Get common communities to two users
-- =========================================================

DROP PROCEDURE IF EXISTS `list_drumates`$
CREATE PROCEDURE `list_drumates`(
)
BEGIN

  SELECT lastname, `name`, email, ctime FROM drumate_csv GROUP BY lastname, `name`, email, ctime  ORDER BY lastname ASC;

END$



-- =========================================================
-- list_by_remit
-- =========================================================
DROP PROCEDURE IF EXISTS `list_by_remit`$
CREATE PROCEDURE `list_by_remit`(
  IN _remit TINYINT(4),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * FROM user_csv WHERE  (remit & _remit)>0 ORDER BY mtime DESC LIMIT _offset, _range;
END$

-- =========================================================
-- lookup_entity
-- =========================================================

DROP PROCEDURE  IF EXISTS `lookup_entity`$
CREATE PROCEDURE `lookup_entity`(
  IN _key VARCHAR(512)
)
BEGIN
  SELECT
    id,
    ident,
    mtime,
    status,
    type,
    vhost,
    headline,
    layout as fallback,
    home_layout as home,
    layout,
    db_name,
    db_host,
    fs_host,
    home_dir,
    area
  FROM entity WHERE ident=_key OR id=_key OR vhost=_key;
END$


-- =========================================================
-- lookup_vhost
-- SHALL BE DEPRECATED
-- =========================================================
DROP PROCEDURE IF EXISTS `lookup_vhost`$
CREATE PROCEDURE `lookup_vhost`(
  IN _site VARCHAR(255),
  IN _visitor VARCHAR(255)
)
BEGIN
  DECLARE _type VARCHAR(40);
  DECLARE _hid VARBINARY(16);
  DECLARE _uid VARBINARY(16);
  SET @priv = 0;

  SELECT `type`, id FROM vhost_view WHERE vhost=_site INTO _type, _hid;
  SELECT id FROM drumate_csv WHERE ident=_visitor OR id=_visitor OR vhost=_visitor INTO _uid;

  IF _type = 'community' THEN
    SELECT privilege FROM membership_csv where uid=_uid and hid=_hid INTO @priv;
    SELECT *, @priv AS privilege FROM vhost_csv WHERE id=_hid;
  ELSEIF _type = 'drumate' THEN
    IF _hid = _uid THEN
      SET @priv = 31; -- = 0b11111
    END IF;
    SELECT *, @priv AS privilege FROM drumate_csv WHERE id=_hid;
  ELSE
    SELECT *, @priv AS privilege FROM entity WHERE id='ffffffffffffffff';
  END IF;

END$

-- =========================================================
-- get_visitor  SHALL BE REPLACED BY get_user
-- =========================================================
DROP PROCEDURE IF EXISTS `get_visitor`$
CREATE PROCEDURE `get_visitor`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARCHAR(16);

  SELECT id FROM entity  WHERE ident=_key OR id=_key INTO _id;
  IF _id IS NULL OR _id = '' THEN
    SET _id = 'ffffffffffffffff';
  END IF;
  SELECT
    entity.id,
    entity.id as `oid`,
    entity.id as `uid`,
    entity.ident,
    entity.db_name,
    remit,
    mtime,
    ctime,
    status,
    profile,
    quota,
    settings,
    IFNULL(unverified_email,'') AS unverified_email,
    (SELECT floor(sum(`space`)) FROM hub INNER JOIN entity using(id) where owner_id=_id) AS disk,
    (SELECT count(*) FROM hub INNER JOIN entity using(id) where owner_id=_id) AS `hubs`,
    concat(firstname, ' ', lastname) as fullname,
    if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online
    FROM entity INNER JOIN (drumate) USING(id) WHERE id=_id;
END$


-- =========================================================
-- Get settings (preferences) information of a drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `get_entity_settings`$
CREATE PROCEDURE `get_entity_settings`(
  IN _id    VARCHAR(120)
)
BEGIN
  
  SELECT id, settings FROM entity WHERE id=_id or ident=_id;
END$



-- =========================================================
-- lookup_huber
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_huber`$
CREATE PROCEDURE `lookup_huber`(
  IN _hid  VARBINARY(16),
  IN _uid  VARBINARY(16)
)
BEGIN
  SELECT * FROM membership_csv WHERE hid=_hid AND uid=_uid;
END$


-- =========================================================
-- lookup_drumate
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_drumate`$
CREATE PROCEDURE `lookup_drumate`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARBINARY(16);

  SELECT id FROM entity  WHERE ident=_key OR id=_key OR vhost=_key INTO _id;
  IF _id IS NULL OR _id = '' THEN
    SET _key = 'ffffffffffffffff';
  END IF;

  SELECT 
    entity.id,
    entity.id as oid,
    entity.ident,
    `type`,
    email,
    dmail,
    backup_email,
    city,
    country,
    mobile,
    category,
    vhost,
    firstname,
    firstname as `name`,
    lastname,
    remit,
    mtime,
    ctime,
    status,
    profile,
    JSON_EXTRACT(`profile`, '$.avatar') AS `avatar`,
    concat(firstname, ' ', lastname) as fullname,
    if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online,
    headline
  FROM entity JOIN (drumate) USING(id) WHERE ident=_key OR id=_key OR vhost=_key;
END$



-- =========================================================
-- lookup_drumate
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_drumates`$
CREATE PROCEDURE `lookup_drumates`(
  IN _key VARCHAR(255),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  IF _key IS NULL OR _key = '' THEN
    SELECT * FROM drumate_csv ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT * FROM drumate_csv WHERE ident=_key OR id=_key OR email=_key;
  END IF;
END$

-- =========================================================
-- lookup_community
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_community`$
CREATE PROCEDURE `lookup_community`(
  IN _key VARCHAR(255)
)
BEGIN
  SELECT * FROM community_view WHERE ident=_key OR id=_key OR dmail=_key;
END$


-- =========================================================
-- Get partial profile from entity, based on type attribute
-- Sensitives columns (db_host, etc.) MUST NOT BE not selected
-- SHOULD BE DEPRECATED
-- =========================================================

DROP PROCEDURE IF EXISTS `lookup_site`$
CREATE PROCEDURE `lookup_site`(
  IN _site VARCHAR(255),
  IN _visitor VARCHAR(255)
)
BEGIN
  DECLARE _type VARCHAR(40);
  DECLARE _hid VARBINARY(16);
  DECLARE _uid VARBINARY(16);
  SET @priv = 0;

  SELECT `type`, id FROM vhost_view WHERE vhost=_site INTO _type, _hid;
  SELECT id FROM drumate_csv WHERE ident=_visitor OR id=_visitor OR vhost=_visitor INTO _uid;

  IF _type = 'community' THEN
    SELECT privilege FROM membership where drumate_id=_uid and hub_id=_hid INTO @priv;
    SELECT *, @priv AS privilege FROM site_view WHERE id=_hid;
  ELSEIF _type = 'drumate' THEN
    IF _hid = _uid THEN
      SET @priv = 31; -- = 0b11111
    END IF;
    SELECT *, @priv AS privilege FROM drumate_csv WHERE id=_hid;
  ELSE
    SELECT *, @priv AS privilege FROM entity WHERE id='ffffffffffffffff';
  END IF;
END$

-- =========================================================
--
-- OLD VERSION
-- =========================================================

-- DROP PROCEDURE IF EXISTS `lookup_hub`$
-- CREATE PROCEDURE `lookup_hub`(
--   IN _key VARCHAR(255)
-- )
-- BEGIN
--   SELECT * FROM hub_csv  WHERE ident LIKE concat("%", _key, "%")
--   OR vhost LIKE concat("%", _key, "%") OR `name` LIKE concat("%", _key, "%");
-- END$


-- =========================================================
-- Get partial user profile from entity, based on type attribute
-- Sensitives columns (db_host, etc.) MUST NOT BE not selected
-- OBSOLETED BY lookup_user
-- =========================================================

-- DROP PROCEDURE IF EXISTS `lookup_profile`$
-- CREATE PROCEDURE `lookup_profile`(
DROP PROCEDURE IF EXISTS `lookup_user`$
CREATE PROCEDURE `lookup_user`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _type VARCHAR(40);
  DECLARE _id VARBINARY(16);

  SELECT `type`,id FROM entity WHERE ident=_key OR id=_key OR vhost=_key INTO _type, _id;

  IF _type = 'community' THEN
    SELECT * FROM community_profile WHERE id=_id;
  ELSEIF _type = 'drumate' THEN
    SELECT * FROM drumate_csv WHERE id=_id;
  ELSE
    SELECT * FROM entity_csv WHERE id='ffffffffffffffff';
  END IF;
END$


*/