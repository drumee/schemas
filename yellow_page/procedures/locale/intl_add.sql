DELIMITER $
DROP PROCEDURE IF EXISTS `intl_add_next`$
CREATE PROCEDURE `intl_add_next`(
  IN _code VARCHAR(128),
  IN _cat VARCHAR(128),
  IN _lng VARCHAR(28),
  IN _des TEXT
)
BEGIN
  REPLACE INTO languages VALUES(null, _code, _cat, _lng, _des);
  SELECT LAST_INSERT_ID() AS id;
END $

DELIMITER ;
