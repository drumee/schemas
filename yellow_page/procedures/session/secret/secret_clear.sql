DELIMITER $

DROP PROCEDURE IF EXISTS `secret_clear`$
CREATE PROCEDURE `secret_clear`(
  IN _uid VARCHAR(16),
  IN _secret VARCHAR(64)
)
BEGIN
  IF _secret = 'all' THEN 
    DELETE FROM secret WHERE uid=_uid;
  ELSE
    DELETE FROM secret WHERE secret=_secret;
  END IF;
END$
DELIMITER ;