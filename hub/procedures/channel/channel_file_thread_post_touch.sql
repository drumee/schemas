DELIMITER $

-- =========================================================
-- channel_file_thread_post_touch
-- Refresh the thread summary after a child message is posted or deleted.
--   _delta = +1 on post, -1 on delete (floored at 0).
-- Also writes the summary onto the root system card's metadata so the folder
-- card can hydrate reply_count / last_message_id / mtime without an extra join.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_post_touch`$
CREATE PROCEDURE `channel_file_thread_post_touch`(
  IN _file_thread_id VARCHAR(16),
  IN _last_message_id VARCHAR(16),
  IN _delta INT
)
BEGIN
  DECLARE _now INT(11) UNSIGNED;
  DECLARE _rc INT DEFAULT 0;
  SET _now = UNIX_TIMESTAMP();

  UPDATE file_thread
    SET last_message_id = _last_message_id,
        reply_count = GREATEST(0, CAST(reply_count AS SIGNED) + _delta),
        mtime = _now
    WHERE root_message_id = _file_thread_id AND status = 'active';

  SELECT reply_count INTO _rc
    FROM file_thread WHERE root_message_id = _file_thread_id AND status = 'active' LIMIT 1;

  UPDATE channel SET metadata = JSON_SET(
      IFNULL(metadata, '{}'),
      '$._file_thread_reply_count', _rc,
      '$._file_thread_last_message_id', _last_message_id,
      '$._file_thread_mtime', _now
    )
    WHERE message_id = _file_thread_id;
END $

DELIMITER ;
