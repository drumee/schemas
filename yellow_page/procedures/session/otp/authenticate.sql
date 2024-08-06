DELIMITER $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `otp_authenticate`$
CREATE PROCEDURE `otp_authenticate`(
  IN _cid VARCHAR(64),
  IN _secret VARCHAR(64), 
  IN _code INT(11)
)
BEGIN
  DECLARE _c INT(11);
  DECLARE _uid VARCHAR(64);
  DECLARE _domain VARCHAR(264);
  DECLARE _org_name VARCHAR(264);
  DECLARE _domain_id INTEGER;
  DELETE FROM otp WHERE UNIX_TIMESTAMP() - ctime > 60*10;
  SELECT `uid` FROM cookie WHERE id=_cid INTO _uid;
  SELECT o.link, o.domain_id, o.name
    FROM organisation o 
    INNER JOIN drumate d ON d.domain_id=o.domain_id 
    INNER JOIN sys_conf s ON s.conf_key= 'support_domain' 
    WHERE d.id=_uid
  INTO _domain, _domain_id, _org_name;
  SELECT IFNULL(code, 'failed') FROM otp WHERE `uid`=_uid 
    AND `secret`=_secret AND `code`=_code INTO _c;
  IF _c != "failed" THEN 
    UPDATE cookie SET failed=0, `status` = 'ok' WHERE id=_cid;
    DELETE FROM otp WHERE `uid`=_uid AND `secret`=_secret AND `code`=_code;
  END IF;
    SELECT
      c.id AS session_id,
      e.id,
      e.ident,
      e.id AS hub_id,
      e.ident as username,
      db_name,
      _domain AS domain,
      _domain_id AS domain_id,
      _org_name AS org_name,
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
      area,
      area_id as aid,
      e.status AS `condition`,
      e.mtime,
      e.ctime,
      concat(firstname, ' ', lastname) as fullname,
      `profile`  
    FROM entity e INNER JOIN (drumate d, cookie c) ON e.id=d.id AND e.id=c.uid 
      WHERE d.id=_uid AND c.id=_cid AND _c != "failed";

END$


DELIMITER ;