DELIMITER $

DROP PROCEDURE IF EXISTS `secret_check`$
CREATE PROCEDURE `secret_check`(
  IN _uid VARCHAR(16),
  IN _secret VARCHAR(64), 
  IN _code INT(10)
)
BEGIN
  -- Set very short timeout (1 second)
  DECLARE CONTINUE HANDLER FOR 1205
  BEGIN
      -- Just continue silently
  END;
  SET SESSION lock_wait_timeout = 1;
  DELETE FROM secret WHERE UNIX_TIMESTAMP() - ctime > 60*30;
  SELECT *, ctime + 60*30 expiry FROM secret WHERE `uid`=_uid 
    AND `secret`=_secret AND `code`=_code;
END$



DELIMITER ;`