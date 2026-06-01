DELIMITER $

DROP PROCEDURE IF EXISTS `channel_read_messages`$
CREATE PROCEDURE `channel_read_messages`(
  IN _msg_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _sys_id INTEGER DEFAULT 0;

  SELECT sys_id FROM channel WHERE message_id = _msg_id INTO _sys_id;

  UPDATE channel SET metadata = JSON_SET(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
  WHERE sys_id <= _sys_id
  AND JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)) = 0;

  SELECT
    sys_id,
    author_id,
    message,
    message_id,
    thread_id,
    attachment,
    status,
    ctime,
    metadata,
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)) = 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata, '$._seen_') = JSON_LENGTH(metadata, '$._delivered_') THEN 1 ELSE 0 END is_seen
  FROM channel WHERE message_id = _msg_id;
END$

DELIMITER ;
