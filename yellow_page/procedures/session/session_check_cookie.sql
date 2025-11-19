DELIMITER $

-- DROP PROCEDURE IF EXISTS `session_check_cookie_next`$
DROP PROCEDURE IF EXISTS `session_check_cookie`$
CREATE PROCEDURE `session_check_cookie`(
  IN _args JSON
)
sp_main: BEGIN
  DECLARE _sid VARCHAR(256);
  DECLARE _device_id VARCHAR(128) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _mfs_token VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _pseudo_entity_uid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _domain VARCHAR(256);
  DECLARE _org_name VARCHAR(256);
  DECLARE _domain_id INTEGER;
  DECLARE _is_support INT DEFAULT 0;
  DECLARE _dmz_hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dmz_token VARCHAR(100);
  DECLARE _ntime INT(11);
  DECLARE _guest_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nobody_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _failed BOOLEAN DEFAULT 0;
  DECLARE _expired BOOLEAN DEFAULT 0;
  DECLARE _connection VARCHAR(16) CHARACTER SET ascii DEFAULT 'new';
  DECLARE _secret VARCHAR(128) CHARACTER SET ascii DEFAULT NULL;

  DECLARE CONTINUE HANDLER FOR 1205
  BEGIN
      -- skip lock that may occures within update
  END;

  SELECT JSON_VALUE(_args, "$.sid") INTO _sid;
  SELECT JSON_VALUE(_args, "$.device_id") INTO _device_id;
  SELECT JSON_VALUE(_args, "$.mfs_token") INTO _mfs_token;

  -- Check if mfs_token is provided
  IF _mfs_token IS NOT NULL THEN
    -- Validate token and get pseudo entity
    SELECT pseudo_entity_uid INTO _pseudo_entity_uid
    FROM yp.mfs_token 
    WHERE token = _mfs_token 
      AND (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP());
    
    IF _pseudo_entity_uid IS NOT NULL THEN
      SELECT _pseudo_entity_uid INTO _uid;
      SELECT 'token' INTO _connection;
      
      -- Return minimal session for token-based access
      SELECT 
        _sid AS session_id,
        _uid AS id,
        _uid AS hub_id,
        1 AS signed_in,
        'mfs_token' AS ident,
        'mfs_token' AS username,
        NULL AS db_name,
        NULL AS dmz_hub_id,
        NULL AS dmz_token,
        'no' AS is_dmz_hub_copy,
        NULL AS domain,
        NULL AS domain_id,
        NULL AS org_name,
        NULL AS home_dir,
        NULL AS home_id,
        NULL AS remit,
        'en' AS lang,
        NULL AS avatar,
        'token' AS `connection`,
        'active' AS status,
        '{}' AS profile,
        UNIX_TIMESTAMP() AS mtime,
        '{}' AS settings,
        NULL AS otp_key,
        'MFS' AS firstname,
        'Token' AS lastname,
        NULL AS mimicker,
        NULL AS mimic_id,
        'normal' AS mimic_type,
        NULL AS mimic_end_at,
        'token' AS profile_type,
        'no' AS intro,
        'MFS Token' AS fullname,
        0 AS is_support;
      LEAVE sp_main;
    END IF;
  END IF;

  START TRANSACTION;

  SELECT get_sysconf('guest_id') INTO _guest_id;
  SELECT get_sysconf('nobody_id') INTO _nobody_id;

  SELECT UNIX_TIMESTAMP() INTO _ntime;

  SELECT `uid` FROM cookie WHERE id=_sid INTO _uid;
  IF _uid IS NULL THEN
    SELECT _nobody_id INTO _uid;
    INSERT IGNORE INTO cookie (`id`,`uid`,`ctime`,`mtime`,`ua`, `status`)
    VALUES(_sid, _uid, _ntime, _ntime, _device_id, _connection);
  ELSE
    SELECT o.secret, IF(unix_timestamp() < (o.ctime + 600), 0, 1) expired
      FROM otp o INNER JOIN cookie c ON c.uid=o.uid
      WHERE c.id=_sid ORDER BY o.ctime DESC LIMIT 1 INTO _secret, _expired;

    -- No pending otp
    IF _secret IS NULL THEN
      SELECT 'ok' INTO _connection;
    ELSE
      IF _expired THEN
        SELECT 'new' INTO _connection;
        UPDATE cookie SET ctime=_ntime, `uid`=_nobody_id, mtime=_ntime, `status`=_connection WHERE id=_sid;
      ELSE
        SELECT 'otp' INTO _connection;
      END IF;
    END IF;
    -- UPDATE cookie SET ctime=_ntime, mtime=_ntime, `status`=_connection WHERE id=_sid;
  END IF;

  SELECT o.link, o.domain_id, o.name
    FROM organisation o
    INNER JOIN drumate d ON d.domain_id=o.domain_id
    INNER JOIN sys_conf s ON s.conf_key= 'support_domain'
    WHERE d.id=_uid
  INTO _domain, _domain_id, _org_name;

  -- checking for dmz

  SELECT map.hub_id, map.id
  FROM drumate d
  INNER JOIN dmz_user ms ON ms.email = d.email
  INNER JOIN dmz_token map on map.guest_id = ms.id
  WHERE d.id =_uid AND map.is_sync = 1 LIMIT 1
  INTO _dmz_hub_id, _dmz_token;

  SELECT
    c.id AS session_id,
    e.id,
    e.id AS hub_id,
    IF(e.id NOT IN (_guest_id, _nobody_id) AND _connection !='otp', 1, 0) as signed_in,
    d.username AS ident,
    d.username as username,
    db_name,
    _dmz_hub_id dmz_hub_id,
    _dmz_token dmz_token,
    IF(_dmz_hub_id IS NOT NULL , 'yes', 'no') is_dmz_hub_copy,
    _domain AS domain,
    _domain_id AS domain_id,
    _org_name AS org_name,
    home_dir,
    home_id,
    remit,
    lang,
    avatar,
    _connection AS `connection`,
    e.status,
    d.profile,
    e.mtime,
    e.settings,
    _secret otp_key,
    COALESCE(c.guest_name, d.firstname) firstname,
    lastname,
    NULL mimicker,
    NULL mimic_id,
    'normal' mimic_type,
    NULL mimic_end_at,
    IFNULL(JSON_value(d.profile, "$.profile_type"),'normal') profile_type,
    IF(JSON_VALUE(`profile`, "$.intro") IS NULL, 'yes', 'no') intro,
    fullname,
    0 is_support
    FROM entity e INNER JOIN drumate d ON e.id=d.id
      INNER JOIN cookie c ON d.id=c.uid
      WHERE d.id=_uid AND c.id=_sid LIMIT 1;

END$

DELIMITER ;