DELIMITER $

-- =========================================================
-- channel_file_thread_trashed_filename
-- Last known user_filename of a node that is no longer live in `media`.
--
-- Used to label a General-chat "file.thread" root card that survives its file:
-- the card stays in the conversation (flagged unavailable) after the file is
-- trashed, and needs a name to stay meaningful.
--
-- Returns no row when the node was purged from the trash, moved to another
-- hub, or was never trashed at all. That last case is deliberate: a file that
-- is still live but unreadable to the caller must not leak its name through
-- this routine, so the caller falls back to a generic label.
--
-- Read-only; the service is responsible for deciding who may see the result.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_trashed_filename`$
CREATE PROCEDURE `channel_file_thread_trashed_filename`(
  IN _file_nid VARCHAR(16)
)
BEGIN
  IF _file_nid IS NULL OR _file_nid = '' THEN
    SELECT NULL AS user_filename WHERE FALSE;
  ELSE
    SELECT t.user_filename
    FROM trash_media t
    LEFT JOIN media m ON m.id = t.id
    WHERE t.id = _file_nid
      -- Only when the node is genuinely gone from live media. A restored file
      -- keeps its trash row in some flows; naming it here would contradict the
      -- caller's own access decision.
      AND m.id IS NULL
    ORDER BY t.trashed_time DESC
    LIMIT 1;
  END IF;
END $

DELIMITER ;
