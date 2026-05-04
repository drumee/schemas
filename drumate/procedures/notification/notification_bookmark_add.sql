DELIMITER $
DROP PROCEDURE IF EXISTS `notification_bookmark_add`$
CREATE PROCEDURE `notification_bookmark_add`(
  IN _message_id VARCHAR(16),
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  -- Derive current user from DB context (drumate DB is per-user)
  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  INSERT IGNORE INTO notification_bookmark (uid, message_id, hub_id, ctime)
  VALUES (_uid, _message_id, _hub_id, UNIX_TIMESTAMP());

  SELECT
    id,
    uid,
    message_id,
    hub_id,
    ctime
  FROM notification_bookmark
  WHERE uid = _uid AND message_id = _message_id;
END $
DELIMITER ;