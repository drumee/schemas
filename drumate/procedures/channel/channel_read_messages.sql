-- ============================================================================
-- DRAFT (Part 2) — for Aaron's review. Drumate-native channel_read_messages
-- with the per-file-thread delta applied to DRUMATE's own version.
--
-- Delta vs drumate's current (template-baked) version, marked -- [ft]:
--   1) the seen-marking UPDATE must NOT mark file-thread replies as seen when
--      the user reads the MAIN chat (thread replies keep their own per-thread
--      read state via channel_file_thread_read_messages) -> AND file_thread_id IS NULL.
--   2) expose file_thread_id in the output.
-- Safe on current data: every existing row has file_thread_id NULL, so the guard
-- is a no-op until real file-thread replies exist -> no behaviour change to today's chat.
-- ============================================================================
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
  AND file_thread_id IS NULL                                        -- [ft] don't mark thread replies seen from main chat
  AND JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)) = 0;

  SELECT
    sys_id,
    author_id,
    message,
    message_id,
    thread_id,
    file_thread_id,                                                 -- [ft] expose thread membership
    attachment,
    status,
    ctime,
    metadata,
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)) = 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata, '$._seen_') = JSON_LENGTH(metadata, '$._delivered_') THEN 1 ELSE 0 END is_seen
  FROM channel WHERE message_id = _msg_id;
END$
DELIMITER ;
