DELIMITER $

-- =========================================================
-- channel_file_thread_read_messages
-- Mark a single file thread seen up to _msg_id. Scoped to file_thread_id, so
-- acknowledging a file chat never clears unread state for sibling folder or
-- workspace messages (and vice versa via channel_read_messages).
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_read_messages`$
CREATE PROCEDURE `channel_file_thread_read_messages`(
  IN _msg_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _file_thread_id VARCHAR(16)
)
BEGIN
  DECLARE _sys_id INTEGER DEFAULT 0;

  SELECT sys_id INTO _sys_id
    FROM channel
    WHERE message_id = _msg_id AND file_thread_id = _file_thread_id;

  IF _sys_id > 0 THEN
    UPDATE channel SET metadata = JSON_SET(metadata, CONCAT('$._seen_.', _uid), UNIX_TIMESTAMP())
    WHERE file_thread_id = _file_thread_id
      AND sys_id <= _sys_id
      AND JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid)) = 0;
  END IF;

  SELECT
    sys_id,
    message_id,
    thread_id,
    file_thread_id,
    metadata,
    CASE WHEN JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid)) = 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata, '$._seen_') >= JSON_LENGTH(metadata, '$._delivered_') THEN 1 ELSE 0 END is_seen
  FROM channel WHERE message_id = _msg_id AND file_thread_id = _file_thread_id;
END $

DELIMITER ;
