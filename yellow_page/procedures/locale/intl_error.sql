DELIMITER $
DROP PROCEDURE IF EXISTS `intl_error`$
CREATE PROCEDURE `intl_error`(
  IN _code VARCHAR(128),
  IN _cat VARCHAR(128),
  IN _lng VARCHAR(28),
  IN _des TEXT
)
BEGIN
  REPLACE INTO languages VALUES(null, _code, 'error', _lng, _des);
  INSERT INTO error VALUES(_code, 1, _code);
END $


DELIMITER ;
