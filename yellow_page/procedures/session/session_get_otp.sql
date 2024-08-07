DELIMITER $

DROP FUNCTION IF EXISTS `session_get_otp`$
CREATE FUNCTION `session_get_otp`(
    _uid VARCHAR(16)
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _key VARCHAR(80) DEFAULT NULL;
  SELECT `secret` FROM otp WHERE uid=_uid ORDER BY ctime DESC LIMIT 1 INTO _key;
  RETURN _key;
END$

DELIMITER ;