DELIMITER $

DROP PROCEDURE IF EXISTS `channel_read_messages`$
CREATE PROCEDURE `channel_read_messages`(
  IN _msg_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _sys_id INTEGER DEFAULT 0;

  SELECT sys_id FROM channel WHERE message_id = _msg_id INTO _sys_id;

  -- Normal read path marks only normal (non-file-thread) messages seen.
  -- File-thread children keep their own per-thread read state via
  -- channel_file_thread_read_messages, so reading the workspace/folder chat
  -- never clears a sibling file thread's unread state.
  UPDATE channel SET metadata = JSON_SET(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
  WHERE sys_id <= _sys_id
  AND file_thread_id IS NULL
  AND JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)) = 0;

  SELECT
    sys_id,
    author_id,
    message,
    message_id,
    thread_id,
    file_thread_id,
    attachment,
    status,
    ctime,
    metadata,
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)) = 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata, '$._seen_') >= JSON_LENGTH(metadata, '$._delivered_') THEN 1 ELSE 0 END is_seen
  FROM channel WHERE message_id = _msg_id;
END$

DELIMITER ;
