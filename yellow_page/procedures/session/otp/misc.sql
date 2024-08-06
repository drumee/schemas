DELIMITER $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `otp_cleanup`$
CREATE PROCEDURE `otp_cleanup`(
)
BEGIN
  DELETE FROM otp WHERE UNIX_TIMESTAMP() - ctime > 5*60;
END$


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `otp_delete`$
CREATE PROCEDURE `otp_delete`(
  IN _uid VARCHAR(16),
  IN _secret VARCHAR(64), 
  IN _code INT(10)
)
BEGIN
  DELETE FROM otp WHERE `uid`=_uid AND `secret`=_secret AND `code`=_code;
END$

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `otp_get`$
CREATE PROCEDURE `otp_get`(
  IN _secret VARCHAR(64), 
  IN _code INT(10)
)
BEGIN
  SELECT `uid` FROM otp WHERE `secret`=_secret AND `code`=_code;
END$


DROP FUNCTION IF EXISTS `otp_get`$
DROP FUNCTION IF EXISTS `otp_get_secret`$

DELIMITER ;