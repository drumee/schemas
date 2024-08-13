DELIMITER $

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `add_member`$
CREATE PROCEDURE `add_member`(
  IN _member_id  VARCHAR(512),
  IN _privilege TINYINT(2),
  IN _expiry_time INT(11)
)
BEGIN
  DECLARE _member_db VARCHAR(30);
  DECLARE _hub_db VARCHAR(30);
  DECLARE _area VARCHAR(30);
  DECLARE _hid VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _guest_id VARCHAR(16);
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;
  DECLARE _ui_privilege TINYINT(4);

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;

  SELECT id, db_name FROM yp.entity WHERE id = _member_id 
    -- OR ident = _member_id 
    INTO _uid, _member_db;

  SELECT id, area FROM yp.entity WHERE db_name = database() INTO _hid, _area;
  SELECT id FROM yp.guest WHERE id = _member_id OR email = _member_id INTO _guest_id;
  
  IF _member_db IS NOT NULL THEN 
    REPLACE INTO permission 
      VALUES(null, '*', _uid, '', _tx, _ts, _ts, _privilege, 'share');

    SET @s = CONCAT("CALL `", _member_db, "`.join_hub(", quote(_hid), ");");
    -- SELECT @s;

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT IF(_privilege < 15, 15, _privilege) INTO _ui_privilege;
    SET @s = CONCAT("REPLACE INTO  `", _member_db, "`.permission VALUES(null, ", 
      "'"  , _hid         , "'," ,
      "'"  , _uid         , "'," ,
      "'"  , "---"        , "'," ,
      "'"  , _expiry_time , "'," ,
      "'"  , _ts          , "'," ,
      "'"  , _ts          , "'," ,
      "'"  , _ui_privilege, "'," ,
      "'"  , 'share'      , "')" 
    );
      
    --   quote(_hid), ", '', ", quote(_uid), "," , 
    --   _expiry_time, ",", _ts, ",", _ts, ",", _privilege, ", 'share');");
    -- -- SELECT @s;

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT
      entity.id,
      entity.ident,
      entity.area_id,
      entity.area,
      entity.db_name,
      entity.vhost,
      drumate.dmail,
      drumate.email,
      drumate.firstname,
      drumate.lastname,
      drumate.remit,
      CONCAT(firstname, ' ', lastname) as `fullname`,
      permission AS permission
    FROM yp.entity INNER JOIN (yp.drumate, permission) ON (drumate.id=entity.id AND 
    permission.entity_id=entity.id)
    WHERE entity.id=_uid;
  ELSEIF _area = 'restricted' AND _guest_id IS NOT NULL THEN
    REPLACE INTO permission 
      VALUES(null, '*', _guest_id, '', _tx, _ts, _ts, _privilege, 'share');
    SELECT
      guest.id,
      guest.email,
      guest.firstname,
      guest.lastname,
      CONCAT(firstname, ' ', lastname) as `fullname`,
      permission AS permission
    FROM yp.guest INNER JOIN (permission) ON guest.id=entity.id WHERE guest.id=_guest_id;
  ELSE
    SELECT _member_db AS db_name, _area AS area, 0 AS permission ;
  END IF;
END$

DELIMITER ;
