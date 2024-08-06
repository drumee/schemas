DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_update_notify`$
CREATE PROCEDURE `dmz_update_notify`(
  IN _token VARCHAR(120)
)
BEGIN
  DECLARE _ts INT(11);
  UPDATE dmz_token SET notify_at = UNIX_TIMESTAMP()
  WHERE id = _token;

END$

DELIMITER ;




