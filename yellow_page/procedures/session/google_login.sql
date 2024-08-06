DELIMITER $

DROP PROCEDURE IF EXISTS `get_redirect_state`$
CREATE PROCEDURE `get_redirect_state`(
  IN _id VARCHAR(16)
)
BEGIN
  SELECT * FROM  redirect_state WHERE id = _id;
END $


DROP PROCEDURE IF EXISTS `set_redirect_state`$
CREATE PROCEDURE `set_redirect_state`(
  IN _id VARCHAR(16),
  _metadata  JSON
)
BEGIN
  REPLACE INTO yp.redirect_state(id,metadata) SELECT _id , _metadata;
  SELECT * FROM  redirect_state WHERE id = _id;
END $


DROP PROCEDURE IF EXISTS `google_login`$
CREATE PROCEDURE `google_login`(
  IN _key VARCHAR(128),
  IN _cid VARCHAR(64),
  IN _domain_name VARCHAR(1000)
)
BEGIN

  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _profile JSON DEFAULT "{}";
  DECLARE _sid VARCHAR(64);
  -- DECLARE _otp VARCHAR(64);
  DECLARE _db_name VARCHAR(52) DEFAULT '0';

  DECLARE _secret VARCHAR(500);
  DECLARE _email VARCHAR(500);
  DECLARE _dom_id INT(8);


  SELECT IFNULL(domain_id,1) FROM `organisation` 
  WHERE link = _domain_name OR domain_id = _domain_name
  INTO _dom_id;

  SELECT e.id, `profile`, db_name, d.email, o.link FROM drumate d 
  INNER JOIN entity e ON e.id=d.id  
  LEFT JOIN organisation o on o.domain_id=e.dom_id
  WHERE (d.username=_key OR e.id=_key OR email=_key) AND o.link = _domain_name
  INTO _uid, _profile, _db_name, _email, _domain_name;

   SELECT id FROM cookie WHERE id=_cid INTO _sid;

    IF _sid IS NULL THEN 
      SELECT 'no_cookie' AS status;
    ELSE

      SELECT IFNULL(JSON_VALUE(_profile, "$.otp"), "") INTO @_otp;
      -- SELECT IF(@_otp IN ("0", ""), _uid, 'ffffffffffffffff') INTO _uid;
      UPDATE cookie SET 
        failed=0, 
        mtime=UNIX_TIMESTAMP(), 
        -- `uid` = IF(_otp IS NULL OR _otp IN (0, "0", ""), _uid, 'ffffffffffffffff'),
        `uid` = _uid, 
        status = 'ok',
        ttl = IFNULL(JSON_VALUE(_profile, "$.session_ttl"), 2592000)
      WHERE id=_cid;

      SELECT
        c.id AS session_id,
        e.id,
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
        null mimic_id,
        null  mimc_type,
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
 END $





DELIMITER ;


