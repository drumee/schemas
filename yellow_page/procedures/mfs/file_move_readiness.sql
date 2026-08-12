DELIMITER $

-- =========================================================
-- file_move_readiness
--
-- Does this database have everything file threads need?
--
-- Diagnostic only — nothing in the request path calls it any more. It stays
-- because a schema can silently lag behind: the procedures below are what
-- read, write, and follow a file thread, and a database missing one of them
-- fails at the moment a user opens a chat, with no earlier warning. Run it
-- after a patch round to find those databases before users do.
--
-- The cross-hub move saga and its migrate helper are deliberately NOT listed.
-- Threads no longer travel between databases — they stay in the workspace that
-- owns them — so the procedures that used to carry them are not part of a
-- healthy instance. See
-- plans/260812-0704-thread-stays-in-original-workspace-on-cross-hub-move/.
--
-- Returns one row: `ready` = 1 when nothing is missing; `missing` lists the
-- absent artifacts comma-separated, for logs and messages — not for branching.
-- =========================================================
DROP PROCEDURE IF EXISTS `file_move_readiness`$
CREATE PROCEDURE `file_move_readiness`(
  IN _db_name VARCHAR(64)
)
BEGIN
  DECLARE _missing TEXT DEFAULT '';

  SELECT GROUP_CONCAT(name ORDER BY name SEPARATOR ',') INTO _missing
  FROM (
    SELECT 'mfs_move_all' AS name
    -- Reading, writing and listing threads.
    UNION ALL SELECT 'channel_file_thread_ensure_root'
    UNION ALL SELECT 'channel_file_thread_info'
    UNION ALL SELECT 'channel_file_thread_list_by_folder'
    UNION ALL SELECT 'channel_file_thread_resolve_access'
    -- Enumerating the threads under a file or folder about to move; read
    -- before the move, because the media rows are gone afterwards.
    UNION ALL SELECT 'channel_file_thread_list_in_subtree'
    UNION ALL SELECT 'file_move_source_snapshot'
    -- Re-pointing a thread at the file when it comes back.
    UNION ALL SELECT 'channel_file_thread_rebind_returned_file'
  ) req
  WHERE NOT EXISTS (
    SELECT 1 FROM mysql.proc p
    WHERE p.db = _db_name AND p.name = req.name
  );

  SET _missing = COALESCE(_missing, '');

  -- The thread table itself. A database can hold every procedure and still be
  -- unusable without it.
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = _db_name AND TABLE_NAME = 'file_thread'
  ) THEN
    SET _missing = CONCAT_WS(',', NULLIF(_missing, ''), 'table:file_thread');
  END IF;

  -- The column that ties a message to its thread.
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = _db_name AND TABLE_NAME = 'channel'
      AND COLUMN_NAME = 'file_thread_id'
  ) THEN
    SET _missing = CONCAT_WS(',', NULLIF(_missing, ''), 'column:channel.file_thread_id');
  END IF;

  SELECT
    _db_name AS db_name,
    IF(_missing = '', 1, 0) AS ready,
    _missing AS missing;
END $

DELIMITER ;
