DELIMITER $


DROP PROCEDURE IF EXISTS `session_signin`$
CREATE PROCEDURE `session_signin`(
  IN _args JSON
)
BEGIN
  DECLARE _key VARCHAR(128);
  DECLARE _pw VARCHAR(128);
  DECLARE _cid VARCHAR(64);
  DECLARE _otp VARCHAR(64) DEFAULT "0";
  DECLARE _domain_name VARCHAR(1000);
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _profile JSON DEFAULT "{}";
  DECLARE _sid VARCHAR(64);
  DECLARE _db_name VARCHAR(52) DEFAULT '0';
  DECLARE _ctime INT(11); 
  DECLARE _email VARCHAR(500);
  DECLARE _dom_id INT(8) DEFAULT 1;

  SELECT JSON_VALUE(_args, "$.username") INTO _key;
  SELECT JSON_VALUE(_args, "$.password") INTO _pw;
  SELECT JSON_VALUE(_args, "$.sid") INTO _cid;
  SELECT IFNULL(JSON_VALUE(_args, "$.host"), main_domain()) INTO _domain_name;

  SELECT IFNULL(dom_id, 1) FROM vhost WHERE fqdn=_domain_name INTO _dom_id;

  SELECT e.id, `profile`, db_name, d.email, o.name FROM drumate d 
    INNER JOIN entity e ON e.id=d.id  
    INNER JOIN domain o ON o.id=e.dom_id
    WHERE fingerprint=sha2(_pw, 512) AND (d.username=_key OR e.id=_key OR email=_key) AND o.id = _dom_id
      INTO _uid, _profile, _db_name, _email, _domain_name;

  SELECT id FROM cookie WHERE id=_cid INTO _sid;

  IF _sid IS NULL THEN 
    SELECT IF(_cid IS NULL OR _cid="", concat(uniqueId(), uniqueId()), _cid) INTO _sid;
    SELECT _sid INTO _cid;
    SELECT UNIX_TIMESTAMP() INTO _ctime;
    INSERT INTO cookie (`id`,`uid`,`ctime`,`mtime`,`ua`, `status`) 
      VALUES(_sid, IFNULL('ffffffffffffffff', _uid), _ctime, _ctime, 'no_cookie', 'new');
  END IF;

  IF _uid IS NULL THEN 
    UPDATE cookie SET failed=failed+1, `status`='wrong_credentials' WHERE id=_cid;
    SELECT id session_id, failed, `status` FROM cookie WHERE id=_cid;
  ELSE
    SELECT IFNULL(JSON_VALUE(_profile, "$.otp"), "") INTO _otp;
    UPDATE cookie SET 
      failed=0, 
      mtime=UNIX_TIMESTAMP(), 
      `uid` = _uid, 
      status = IF(_otp IN ("0", ""), 'ok', 'otp'),
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
      area,
      area_id as aid,
      e.status AS `condition`,
      e.mtime,
      e.ctime,
      _profile AS `profile`
    FROM entity e INNER JOIN (drumate d, cookie c) ON e.id=d.id AND e.id=c.uid 
      WHERE d.id=_uid AND c.id=_cid;
  END IF;
END$

DELIMITER ;