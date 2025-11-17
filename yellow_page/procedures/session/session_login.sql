DELIMITER $


-- DROP PROCEDURE IF EXISTS `session_login`$

DROP PROCEDURE IF EXISTS `session_login_next`$
CREATE PROCEDURE `session_login_next`(
  IN _key VARCHAR(128),
  IN _pw VARCHAR(128),
  IN _cid VARCHAR(64),
  IN _domain_name VARCHAR(1000)
)
BEGIN
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _profile JSON DEFAULT "{}";
  DECLARE _sid VARCHAR(64);
  -- DECLARE _otp VARCHAR(64);
  DECLARE _db_name VARCHAR(52) DEFAULT '0';
  DECLARE _ctime INT(11); 


  DECLARE _mimicker VARCHAR(64);
  DECLARE _mimic_id VARCHAR(16);
  DECLARE _mimic_type VARCHAR(30) default  'normal';
  DECLARE _mimic_entity JSON;

  DECLARE _secret VARCHAR(500);
  DECLARE _email VARCHAR(500);
  DECLARE _dom_id INT(8);

  SELECT IFNULL(domain_id,1) FROM `organisation` 
    WHERE link = _domain_name OR domain_id = _domain_name
    INTO _dom_id;

  SELECT e.id, `profile`, db_name, d.email, o.link FROM drumate d 
    INNER JOIN entity e ON e.id=d.id  
    LEFT JOIN organisation o on o.domain_id=e.dom_id
    WHERE fingerprint=sha2(_pw, 512) AND (d.username=_key OR e.id=_key OR email=_key)
      AND o.link = _domain_name
      INTO _uid, _profile, _db_name, _email, _domain_name;

  SELECT secret FROM token WHERE email = _email AND method = 'signup' ORDER BY 
    ctime DESC LIMIT 1 INTO _secret;

  IF _uid IS NULL THEN 
    UPDATE cookie SET failed=failed+1, `status`='wrong_credentials' WHERE id=_cid;
    SELECT failed, `status` FROM cookie WHERE id=_cid;
  ELSE
    SELECT id FROM cookie WHERE id=_cid INTO _sid;
    IF _sid IS NULL THEN 
      SELECT _cid INTO _sid;
      SELECT UNIX_TIMESTAMP() INTO _ctime;
      INSERT INTO cookie (`id`,`uid`,`ctime`,`mtime`,`ua`, `status`)
        VALUES(_sid, _uid, _ctime, _ctime, 'no_cookie', 'new');
    END IF;
    
    SELECT 'victim' ,mimicker, id FROM mimic WHERE status = 'active' AND uid = _uid INTO  _mimic_type , _mimicker, _mimic_id ;
    SELECT 'old', mimicker, id  FROM mimic WHERE status = 'active' AND mimicker = _uid  INTO  _mimic_type , _mimicker, _mimic_id;
    SELECT 'mimc', m.mimicker, m.id  FROM mimic m
    INNER JOIN cookie c ON  m.uid = c.uid AND m.mimicker = c.mimicker 
    WHERE   m.status ='active' AND  c.id = _sid AND c.uid = _uid   INTO _mimic_type ,_mimicker, _mimic_id;

--  if oldmimc , then change it to normal.
    IF _mimic_type = 'old' THEN 
      UPDATE mimic SET status = 'endbytime'  WHERE id = _mimic_id;
      UPDATE mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('endbytime',  UNIX_TIMESTAMP())) WHERE id=_mimic_id;
      UPDATE cookie SET uid=_mimicker , mimicker=null WHERE mimicker=_mimicker ;
      SELECT 'normal' INTO _mimic_type; 
    END IF;

    SELECT IFNULL(JSON_VALUE(_profile, "$.otp"), "") INTO @_otp;
    -- SELECT IF(@_otp IN ("0", ""), _uid, 'ffffffffffffffff') INTO _uid;
    UPDATE cookie SET 
      failed=0, 
      mtime=UNIX_TIMESTAMP(), 
      -- `uid` = IF(_otp IS NULL OR _otp IN (0, "0", ""), _uid, 'ffffffffffffffff'),
      `uid` = _uid, 
      status = IF(@_otp IN ("0", ""), 'ok', 'otp'),
      ttl = IFNULL(JSON_VALUE(_profile, "$.session_ttl"), 2592000)
    WHERE id=_cid;
    SELECT
      c.id AS session_id,
      e.id,
      e.id AS hub_id,
      d.username AS ident,
      d.username,
      d.fullname,
      _domain_name AS domain,
      _dom_id AS domain_id,
      db_name,
      db_host,
      fs_host,
      vhost,
      home_dir,
      home_id,
      c.status,
      email,
      dmail,
      firstname,
      lastname,
      mimicker,
      _mimic_id mimic_id,
      _mimic_type mimc_type,
      area,
      area_id as aid,
      e.status AS `condition`,
      e.mtime,
      e.ctime,
      _profile AS `profile`,
      _secret `secret`
    FROM entity e INNER JOIN (drumate d, cookie c) ON e.id=d.id AND e.id=c.uid 
      WHERE d.id=_uid AND c.id=_cid;
  END IF;
END$

DELIMITER ;