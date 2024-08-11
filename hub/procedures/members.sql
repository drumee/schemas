DELIMITER $

-- =========================================================
-- get_expired_huber
-- Gets hubers with expired access.
-- =========================================================

DROP PROCEDURE IF EXISTS `get_expired_huber`$
CREATE PROCEDURE `get_expired_huber`()
BEGIN
  SELECT * FROM huber WHERE (expiry_time <> 0 AND expiry_time < UNIX_TIMESTAMP());
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `add_huber`$
CREATE PROCEDURE `add_huber`(
  IN _key  VARCHAR(80),
  IN _privilege INT(8),
  IN _expiry_time INT(11)
)
BEGIN
  DECLARE _db VARCHAR(30);
  DECLARE _hid VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _ts INT(11) DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;
  SELECT id FROM yp.drumate WHERE email=_key INTO _uid;
  SELECT db_name, id FROM yp.entity WHERE id=_key OR
    (IFNULL(_uid, '') <> "" AND id = _uid) INTO _db, _uid;

  IF (IFNULL(_uid, '') = "") THEN
    SELECT 1 AS non_drumate;
  ELSE
    INSERT into huber values(null, _uid, _privilege, IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))), _ts, _ts)
      ON DUPLICATE KEY UPDATE privilege=_privilege,
      expiry_time = IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))),
      utime = _ts;

    SET @s = CONCAT("CALL `", _db, "`.join_hub(", quote(_hid), ");");
    -- SELECT @s;

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT
      0 AS non_drumate,
      entity.id,
      entity.ident,
      entity.area_id,
      entity.area,
      entity.vhost,
      drumate.dmail,
      drumate.email,
      drumate.firstname,
      drumate.lastname,
      drumate.remit,
      drumate.fullname,
      privilege
    FROM yp.entity INNER JOIN (yp.drumate, huber) ON (drumate.id=entity.id AND huber.id=entity.id)
    WHERE entity.id=_uid;
  END IF;
END $

-- =========================================================
-- MOVED TO meber
-- =========================================================
-- DROP PROCEDURE IF EXISTS `add_member`$
-- CREATE PROCEDURE `add_member`(
--   IN _member_id  VARCHAR(512),
--   IN _privilege TINYINT(2),
--   IN _expiry_time INT(11)
-- )
-- BEGIN
--   DECLARE _member_db VARCHAR(30);
--   DECLARE _hub_db VARCHAR(30);
--   DECLARE _area VARCHAR(30);
--   DECLARE _hid VARCHAR(16);
--   DECLARE _uid VARCHAR(16);
--   DECLARE _guest_id VARCHAR(16);
--   DECLARE _ts INT(11) DEFAULT 0;
--   DECLARE _tx INT(11) DEFAULT 0;
--   DECLARE _ui_privilege TINYINT(4);

--   SELECT UNIX_TIMESTAMP() INTO _ts;
--   SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
--     UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;

--   SELECT id, db_name FROM yp.entity WHERE id = _member_id 
--     -- OR ident = _member_id 
--     INTO _uid, _member_db;

--   SELECT id, area FROM yp.entity WHERE db_name = database() INTO _hid, _area;
--   SELECT id FROM yp.guest WHERE id = _member_id OR email = _member_id INTO _guest_id;
  
--   IF _member_db IS NOT NULL THEN 
--     REPLACE INTO permission 
--       VALUES(null, '*', _uid, '', _tx, _ts, _ts, _privilege, 'share');

--     SET @s = CONCAT("CALL `", _member_db, "`.join_hub(", quote(_hid), ");");
--     -- SELECT @s;

--     PREPARE stmt FROM @s;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--     SELECT IF(_privilege < 15, 15, _privilege) INTO _ui_privilege;
--     SET @s = CONCAT("REPLACE INTO  `", _member_db, "`.permission VALUES(null, ", 
--       "'"  , _hid         , "'," ,
--       "'"  , _uid         , "'," ,
--       "'"  , "---"        , "'," ,
--       "'"  , _expiry_time , "'," ,
--       "'"  , _ts          , "'," ,
--       "'"  , _ts          , "'," ,
--       "'"  , _ui_privilege, "'," ,
--       "'"  , 'share'      , "')" 
--     );
      
--     --   quote(_hid), ", '', ", quote(_uid), "," , 
--     --   _expiry_time, ",", _ts, ",", _ts, ",", _privilege, ", 'share');");
--     -- -- SELECT @s;

--     PREPARE stmt FROM @s;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;

--     SELECT
--       entity.id,
--       entity.ident,
--       entity.area_id,
--       entity.area,
--       entity.db_name,
--       entity.vhost,
--       drumate.dmail,
--       drumate.email,
--       drumate.firstname,
--       drumate.lastname,
--       drumate.remit,
--       CONCAT(firstname, ' ', lastname) as `fullname`,
--       permission AS permission
--     FROM yp.entity INNER JOIN (yp.drumate, permission) ON (drumate.id=entity.id AND 
--     permission.entity_id=entity.id)
--     WHERE entity.id=_uid;
--   ELSEIF _area = 'restricted' AND _guest_id IS NOT NULL THEN
--     REPLACE INTO permission 
--       VALUES(null, '*', _guest_id, '', _tx, _ts, _ts, _privilege, 'share');
--     SELECT
--       guest.id,
--       guest.email,
--       guest.firstname,
--       guest.lastname,
--       CONCAT(firstname, ' ', lastname) as `fullname`,
--       permission AS permission
--     FROM yp.guest INNER JOIN (permission) ON guest.id=entity.id WHERE guest.id=_guest_id;
--   ELSE
--     SELECT _member_db AS db_name, _area AS area, 0 AS permission ;
--   END IF;
-- END$

  -- IF (IFNULL(_uid, '') = "") THEN
  --   SELECT id FROM yp.guest WHERE id = _member_id OR email = _member_id 
  --     INTO _uid;
  --   IF (IFNULL(_uid, '') = "") THEN
  --     SELECT 0 AS permission ;
  --   ELSEIF area = 'restricted' THEN
  --     REPLACE INTO member VALUES(null, _uid);
  --     REPLACE INTO permission VALUES(null, '*', _uid, null, _tx, _ts, _ts, _privilege);
  --     SELECT
  --       guest.id,
  --       guest.email,
  --       guest.firstname,
  --       guest.lastname,
  --       CONCAT(firstname, ' ', lastname) as `fullname`,
  --       permission AS permission
  --     FROM yp.guest INNER JOIN (permission) ON guest.id=entity.id 
  --     WHERE guest.id=_uid;
  --   ELSE
  --     SELECT 0 AS permission ;
  --   END IF;
  -- ELSE
  --   REPLACE INTO member VALUES(null, _uid);
  --   REPLACE INTO permission VALUES(null, '*', _uid, null, _tx, _ts, _ts, _privilege);

  --   SET @s = CONCAT("CALL `", _member_db, "`.join_hub_next(", 
  --     quote(_hid), ",",
  --     _privilege, ",",
  --     _expiry_time, ");"
  --   );
  --   -- SELECT @s;

  --   PREPARE stmt FROM @s;
  --   EXECUTE stmt;
  --   DEALLOCATE PREPARE stmt;

  --   SELECT
  --     entity.id,
  --     entity.ident,
  --     entity.area_id,
  --     entity.area,
  --     entity.vhost,
  --     drumate.dmail,
  --     drumate.email,
  --     drumate.firstname,
  --     drumate.lastname,
  --     drumate.gender,
  --     drumate.remit,
  --     CONCAT(firstname, ' ', lastname) as `fullname`,
  --     permission AS permission
  --   FROM yp.entity INNER JOIN (yp.drumate, permission) ON (drumate.id=entity.id AND 
  --   permission.entity_id=entity.id)
  --   WHERE entity.id=_uid;
  -- END IF;
-- END $


-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `remove_member`$
CREATE PROCEDURE `remove_member`(
  IN _key  VARCHAR(80)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(80);
  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;
  SELECT id, db_name  FROM yp.entity WHERE id=_key INTO _uid, _drumate_db;
  -- DELETE FROM member WHERE id = _uid;
  DELETE FROM permission WHERE entity_id = _uid;
  SET @s1 = CONCAT("DELETE FROM `", _drumate_db, "`.permission ",
    " WHERE resource_id = ", quote(_hub_id), ";");
  SET @s2 = CONCAT("DELETE FROM `", _drumate_db, "`.media ",
    " WHERE id = ", quote(_hub_id), ";");
  PREPARE stmt FROM @s1;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  PREPARE stmt FROM @s2;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  SELECT _uid AS id, 0 AS permission;
END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `remove_all_members`$
CREATE PROCEDURE `remove_all_members`(
  IN _keep_id  VARCHAR(16)
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(40);
  DECLARE _uid VARCHAR(16);
  DECLARE _perm TINYINT(2);
  DECLARE _members CURSOR FOR SELECT entity_id, permission FROM permission WHERE entity_id != '*';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1; 

  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;

  OPEN _members;

  WHILE NOT _done DO
    FETCH _members INTO _uid, _perm;
    IF _uid != _keep_id THEN
      -- DELETE FROM permission WHERE entity_id = _uid;

      SELECT db_name  FROM yp.entity WHERE id=_uid INTO  _drumate_db;

     IF (_drumate_db IS NOT NULL) THEN 
        SET @s = CONCAT(
          "DELETE FROM `", _drumate_db, "`.permission WHERE resource_id = ", quote(_hub_id), ";"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SET @s = CONCAT(
          "DELETE FROM `", _drumate_db, "`.media WHERE id = ", quote(_hub_id), ";"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

      SELECT NULL INTO _drumate_db; 
    END IF;
  END WHILE;
  CLOSE _members;
  DELETE FROM permission WHERE entity_id != _keep_id AND entity_id != '*' ;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `set_member_pemission`$
CREATE PROCEDURE `set_member_pemission`(
  IN _key  VARCHAR(80),
  IN _perm  TINYINT(2)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(80);
  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;
  SELECT id, db_name  FROM yp.entity WHERE id=_key INTO _uid, _drumate_db;
  UPDATE permission SET permission=_perm, utime=UNIX_TIMESTAMP() WHERE entity_id = _uid;
  SET @s = CONCAT("UPDATE `", _drumate_db, "`.permission SET permission=", _perm, 
    " WHERE resource_id = ", quote(_hub_id), ";");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  SELECT @s;
  SELECT * FROM permission WHERE entity_id = _uid;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `remove_huber`$
CREATE PROCEDURE `remove_huber`(
  IN _key  VARCHAR(80)
)
BEGIN
  DECLARE _db VARCHAR(30);
  DECLARE _hid VARBINARY(16);
  DECLARE _uid VARBINARY(16);
  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;
  SELECT db_name, id FROM yp.entity WHERE id=_key INTO _db, _uid;
  IF IFNULL(_uid, '') <> '' THEN
    SET @s = CONCAT("CALL `", _db, "`.remove_from_my_hub(", quote(_hid), ");");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    DELETE FROM huber WHERE id = _uid;
  END IF;
END $

-- =========================================================
--
-- =========================================================

DROP PROCEDURE IF EXISTS `check_huber`$
CREATE PROCEDURE `check_huber`(
  IN _uid  VARCHAR(16)
)
BEGIN

  SELECT
    entity.id,
    entity.ident,
    entity.area_id,
    entity.area,
    entity.vhost,
    drumate.dmail,
    drumate.email,
    drumate.firstname,
    drumate.lastname,
    drumate.remit,
    CONCAT(firstname, ' ', lastname) as `fullname`,
    privilege
  FROM yp.entity INNER JOIN (yp.drumate, huber) ON (drumate.id=entity.id AND huber.id=entity.id) WHERE id=_uid;

END $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `show_hubers`$
CREATE PROCEDURE `show_hubers`(
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _hid VARBINARY(16);
  DECLARE _range bigint;
  DECLARE _offset bigint;

  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;

  CALL pageToLimits(_page, _offset, _range);
  SELECT
    _page as `page`,
    _hid as hub_id,
    entity.id,
    entity.ident,
    entity.area,
    entity.vhost,
    drumate.dmail,
    drumate.email,
    drumate.firstname,
    drumate.lastname,
    drumate.remit,
    CONCAT(firstname, ' ', lastname) as `fullname`,
    privilege
  FROM yp.entity INNER JOIN (yp.drumate, huber) ON drumate.id=entity.id AND huber.id=entity.id;
END $

-- =========================================================
-- Update each member (huber) hubs tables
-- =========================================================

DROP PROCEDURE IF EXISTS `update_membership`$
CREATE PROCEDURE `update_membership`(
   IN _operation VARCHAR(20)
)
BEGIN

  DECLARE _done INT DEFAULT 0;
  DECLARE _id VARBINARY(16);
  DECLARE _hid VARBINARY(16);
  DECLARE _db_name VARCHAR(20);
  DECLARE _hubers CURSOR FOR SELECT id FROM huber;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _done = 1;


  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;

  OPEN _hubers;

  REPEAT
    FETCH _hubers INTO _id;
    SELECT db_name FROM yp.entity WHERE id=_id INTO _db_name;

    IF _operation = 'add' THEN
      -- SET @s = CONCAT("INSERT IGNORE INTO `",_db_name,"`.hubs (`id`) VALUE(", quote(_hid), ")" );
      SET @s = CONCAT("INSERT IGNORE INTO `",_db_name,"`.media (id, origin_id, file_path, user_filename, parent_id, parent_path,
        extension, mimetype, category, filesize, `geometry`, upload_time, publish_time,
        metadata, caption, `status`, approval) SELECT hub.id, owner_id, vhost, hub.name,
        (SELECT id FROM media WHERE parent_id='0' LIMIT 1), '', entity.area,
        'text/plain', 'hub', entity.space, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(),
        '', '', 'active', 'submitted' FROM yp.hub JOIN(yp.entity) ON hub.id=entity.id
        WHERE hub.id=", quote(_hid));
    ELSEIF _operation = 'remove' THEN
      -- SET @s = CONCAT("DELETE FROM `",_db_name,"`.hubs WHERE id=", quote(_hid) );
      SET @s = CONCAT("DELETE FROM `",_db_name,"`.media WHERE id=", quote(_hid) );
    ELSE
      SET @s = "SELECT NULL";
    END IF;

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  UNTIL _done END REPEAT;

  CLOSE _hubers;

END $

-- =========================================================
-- 
-- =========================================================

DROP PROCEDURE IF EXISTS `get_contributors_next`$
DROP PROCEDURE IF EXISTS `get_contributors`$
CREATE PROCEDURE `get_contributors`(
  IN _privilege    INT(4),
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);
  SELECT COUNT(*) FROM member INTO _count;
  SELECT id FROM yp.entity WHERE db_name = database() INTO _hub_id;
  IF _privilege IS NULL OR _privilege = 0 THEN
    SELECT 0x3F INTO _p;
  ELSE
    SELECT _privilege INTO _p;
  END IF;

  SELECT _page as `page`,
    drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id != _hub_id AND (_p & permission > 0) AND expiry_time <>-1
    ORDER BY firstname ASC LIMIT _offset, _range;
END $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `lookup_hubers`$
CREATE PROCEDURE `lookup_hubers`(
  IN _name   VARCHAR(255),
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    d.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl
    FROM permission LEFT JOIN yp.drumate d ON entity_id=d.id 
    WHERE d.id IS NOT NULL AND (
      firstname LIKE CONCAT("%", _name, "%") OR       
      lastname LIKE CONCAT("%", _name, "%") OR       
      mobile LIKE CONCAT("%", _name, "%") OR      
      email LIKE CONCAT("%", _name, "%")       
    )
    ORDER BY firstname ASC LIMIT _offset, _range;
END $

-- =========================================================
-- 
-- =========================================================

DROP PROCEDURE IF EXISTS `show_contributors`$
CREATE PROCEDURE `show_contributors`(
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);
  SELECT COUNT(*) FROM member INTO _count;
  SELECT id FROM yp.entity WHERE db_name = database() INTO _hub_id;

  SELECT 
    _page as `page`,
    drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    expiry_time AS expiry,
    permission.ctime, 
    permission.utime, 
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id != _hub_id ORDER BY permission DESC LIMIT _offset, _range;
END $

-- =======================================================================
--
-- =======================================================================

DROP PROCEDURE IF EXISTS `change_owner`$
CREATE PROCEDURE `change_owner`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _ts INT(11);
  DECLARE _finished INTEGER DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS  _mid_tmp;  
  CREATE TEMPORARY TABLE `_mid_tmp` (db_name   VARCHAR(50));
  INSERT INTO _mid_tmp SELECT db_name FROM permission 
    LEFT JOIN yp.entity e ON entity_id=e.id WHERE permission&32>0 AND resource_id='*';

  BEGIN 
    DECLARE dbcursor CURSOR FOR SELECT db_name FROM _mid_tmp;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
    WHILE NOT _finished DO 
      FETCH dbcursor INTO _db_name;
      SET @s = CONCAT(
        "UPDATE `" ,_db_name,"`.permission SET permission=31, ", 
        "utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
      -- SELECT @s;
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END WHILE;
  END;

  -- Reset old permission
  UPDATE permission SET permission=31, utime = UNIX_TIMESTAMP()
    WHERE permission&32>0 AND resource_id='*';

  -- Set new permission
  REPLACE INTO permission VALUES(NULL, '*', _uid, '', 0, _ts, _ts, 63, 'share');

  SELECT db_name FROM yp.entity WHERE id=_uid INTO _db_name;
  SET @s = CONCAT(
    "UPDATE `" ,_db_name,"`.permission SET permission=63, ", 
    "utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
  -- SELECT @s;
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  -- Set register new owner
  UPDATE yp.hub SET owner_id=_uid WHERE id=_hub_id;

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE entity_id = _uid;

END $


-- =======================================================================
--
-- =======================================================================

DROP PROCEDURE IF EXISTS `members_set_privilege`$
CREATE PROCEDURE `members_set_privilege`(
  IN _privilege INT(4)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _finished INTEGER DEFAULT 0;


  -- TO DO : PROPAGET CHANGES IN USERS table media
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS  _mid_tmp;  
  CREATE TEMPORARY TABLE `_mid_tmp` (db_name   VARCHAR(50));
  INSERT INTO _mid_tmp SELECT db_name FROM permission 
    LEFT JOIN yp.entity e ON entity_id=e.id WHERE permission < 31;

  BEGIN 
    DECLARE dbcursor CURSOR FOR SELECT db_name FROM _mid_tmp;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
    WHILE NOT _finished DO 
      FETCH dbcursor INTO _db_name;
      IF _db_name IS NOT NULL THEN 
        SET @s = CONCAT(
          "UPDATE `" ,_db_name,"`.permission SET permission=",_privilege, 
          ", utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        -- SELECT @s;
      END IF;
    END WHILE;
  END;
  UPDATE permission SET permission=_privilege, utime = UNIX_TIMESTAMP()
    WHERE resource_id='*' AND permission < 31; 

  SELECT 
    p.entity_id AS uid,
    d.firstname,
    JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')) AS email,permission as privilege,
    d.lastname
  FROM permission p INNER JOIN (yp.drumate d) ON 
    p.entity_id=d.id;

END $

-- =======================================================================
--
-- =======================================================================


-- DROP PROCEDURE IF EXISTS `member_get_privilege`$
DROP PROCEDURE IF EXISTS `member_show_privilege`$
CREATE PROCEDURE `member_show_privilege`(
  _uid VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);


  SELECT drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id = _uid and resource_id='*';
END $


DROP PROCEDURE IF EXISTS `get_pr_node_attr`$
CREATE PROCEDURE `get_pr_node_attr`(
   IN _node_id VARCHAR(16)
)
BEGIN

  SELECT 
      d.id entity_id ,  
      user_permission (d.id ,_node_id ) AS privilege, 
      d.email email,
      _node_id resource_id,
      yp.duration_days( user_expiry(d.id ,_node_id ))days,
      yp.duration_hours( user_expiry(d.id ,_node_id ))hours,
      read_json_object(d.profile, 'firstname') AS firstname,
      read_json_object(d.profile, 'lastname') AS lastname
  FROM
  (SELECT distinct entity_id FROM permission WHERE  expiry_time <>-1 ) p
  INNER JOIN yp.drumate d on p.entity_id=d.id 
  WHERE  user_permission (d.id ,_node_id ) > 0 ;

END$



DELIMITER ;
