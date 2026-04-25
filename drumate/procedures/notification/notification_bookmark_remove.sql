DELIMITER $
DROP PROCEDURE IF EXISTS `notification_bookmark_remove`$
CREATE PROCEDURE `notification_bookmark_remove`(
  IN _message_id VARCHAR(16)
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  DELETE FROM notification_bookmark
  WHERE uid = _uid AND message_id = _message_id;

  SELECT ROW_COUNT() AS affected;
END $
DELIMITER ;