DELIMITER $

DROP PROCEDURE IF EXISTS `session_login_otp`$
CREATE PROCEDURE `session_login_otp`(
  IN _key VARCHAR(128),
  IN _code VARCHAR(128),
  IN _secret VARCHAR(64),
  IN _cid VARCHAR(64)
)
BEGIN
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _profile JSON DEFAULT "{}";
  DECLARE _sid VARCHAR(64);
  DECLARE _otp VARCHAR(64);
  DECLARE _db_name VARCHAR(52) DEFAULT '0';
  DECLARE _c INT(11);
  DECLARE _status VARCHAR(64) DEFAULT 'missed';

   DELETE FROM otp WHERE UNIX_TIMESTAMP() - ctime > 60*10;

   SELECT entity.id, `profile`, db_name FROM entity JOIN drumate USING(id)
   WHERE (id=_key OR email=_key)
   INTO _uid, _profile, _db_name;
  
    SELECT IFNULL(code, 'failed') FROM otp WHERE `uid`=_uid
    AND `secret`=_secret AND `code`=_code INTO _c;

    SELECT id FROM cookie WHERE  id=_cid INTO _sid;

    IF _c != "failed" AND _sid IS NOT NULL THEN
      UPDATE cookie SET  uid = _uid ,  failed=0, `status` = 'ok' WHERE id=_cid;
      SELECT 'success' INTO _status; 
    END IF ;     

END$





DROP PROCEDURE IF EXISTS `session_login_b2b`$
CREATE PROCEDURE `session_login_b2b`(
  IN _key VARCHAR(128),
  IN _secret varchar(255),
  IN _cid VARCHAR(64)
)
BEGIN
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _profile JSON DEFAULT "{}";
  DECLARE _sid VARCHAR(64);
  DECLARE _otp VARCHAR(64);
  DECLARE _db_name VARCHAR(52) DEFAULT '0';
  DECLARE _c VARCHAR(11);
  DECLARE _status VARCHAR(64) DEFAULT 'missed';

   DELETE FROM otp WHERE UNIX_TIMESTAMP() - ctime > 60*10;

   SELECT entity.id, `profile`, db_name FROM entity JOIN drumate USING(id)
   WHERE (id=_key OR email=_key)
   INTO _uid, _profile, _db_name;

    SELECT 'failed' INTO  _c;
    SELECT  '9999'  from  yp.token WHERE   
    secret = _secret AND JSON_VALUE(metadata, '$.uid') = _key  INTO  _c;
  

    -- SELECT IFNULL(code, 'failed') FROM otp WHERE `uid`=_uid
    -- AND `secret`=_secret AND `code`=_code INTO _c;
  
    SELECT id FROM cookie WHERE  id=_cid INTO _sid;

    IF _c != "failed" AND _sid IS NOT NULL THEN
      UPDATE cookie SET  uid = _uid ,  failed=0, `status` = 'ok' WHERE id=_cid;
      SELECT 'success' INTO _status; 
    END IF ;     

END$


DELIMITER ;