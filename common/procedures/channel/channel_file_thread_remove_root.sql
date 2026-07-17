DELIMITER $

-- =========================================================
-- channel_file_thread_remove_root
-- Rollback an orphan thread: soft-delete the file_thread row and remove the
-- folder-visible root card. Called by the service ONLY when the first child
-- message fails after channel_file_thread_ensure_root reserved a new thread,
-- and BEFORE any broadcast. Restricted to the creator so a concurrent sender
-- cannot drop another user's just-created thread.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_remove_root`$
CREATE PROCEDURE `channel_file_thread_remove_root`(
  IN _file_thread_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  UPDATE file_thread
    SET status = 'deleted', mtime = UNIX_TIMESTAMP()
    WHERE root_message_id = _file_thread_id AND created_by = _uid;

  -- Same creator guard as the soft-delete above: the root card's author_id is
  -- the thread creator, so a concurrent sender cannot drop another user's card.
  DELETE FROM channel WHERE message_id = _file_thread_id AND author_id = _uid;
END $

DELIMITER ;
