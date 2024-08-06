DELIMITER $


DROP PROCEDURE IF EXISTS `signup_login`$
CREATE PROCEDURE `signup_login`(
  IN _key VARCHAR(128),
  IN _secret VARCHAR(64),
  IN _cid VARCHAR(64)
)
BEGIN
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _email VARCHAR(1000);
  DECLARE _sid VARCHAR(64);
  DECLARE _otp VARCHAR(64);
  

  SELECT t.email FROM token t  WHERE t.secret = _secret INTO _email;
  SELECT id FROM drumate WHERE (id=_key OR email=_key) AND email = _email INTO _uid;  
  
  UPDATE cookie SET  uid = _uid ,  failed=0, `status` = 'ok' WHERE id=_cid;
 END$



DELIMITER ;