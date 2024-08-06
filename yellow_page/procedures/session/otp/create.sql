DELIMITER $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `otp_create`$
CREATE PROCEDURE `otp_create`(
  IN _uid VARCHAR(16),
  IN _secret VARCHAR(64)
)
BEGIN
  DECLARE _code INT(11);
  SELECT LPAD(ROUND(RAND()*1000000), 6, 0) INTO _code;
  INSERT IGNORE 
    INTO otp(`uid`, `secret`, `code`, `ctime`) 
    VALUE(_uid, _secret, _code, UNIX_TIMESTAMP());
  SELECT *, ctime + 60*10 expiry FROM otp WHERE `secret`=_secret;
END$
DELIMITER ;