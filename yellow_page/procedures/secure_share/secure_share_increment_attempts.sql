DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_increment_attempts`$
CREATE PROCEDURE `secure_share_increment_attempts`(
  IN _token VARCHAR(80)
)
BEGIN
  DECLARE _cur TINYINT UNSIGNED DEFAULT 0;

  SELECT failed_attempts INTO _cur
  FROM `secure_share_token`
  WHERE id = _token
  LIMIT 1;

  UPDATE `secure_share_token`
  SET
    failed_attempts = _cur + 1,
    locked_at = IF(_cur + 1 >= 3, UNIX_TIMESTAMP(), locked_at)
  WHERE id = _token;
END$

DELIMITER ;
