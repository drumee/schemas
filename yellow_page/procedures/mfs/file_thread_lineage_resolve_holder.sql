DELIMITER $

-- =========================================================
-- file_thread_lineage_resolve_holder
--
-- Every thread, in any workspace, that is waiting on the file currently at
-- (hub, nid).
--
-- Returns a SET, not one row. The same file can be discussed in several
-- workspaces: it is moved to B, someone there starts their own thread, and now
-- two conversations track the same file from different homes. A move has to
-- act on all of them — waking the one whose workspace the file is entering,
-- and leaving the rest asleep.
--
-- For each row the caller compares current_hub_id (where that thread lives)
-- against the destination:
--
--   no rows                       no thread anywhere is waiting on this file
--   current_hub_id = destination  that thread's file is coming home -> move_back
--   current_hub_id = anything else that thread stays asleep         -> track_holder
--
-- Read-only.
-- =========================================================
DROP PROCEDURE IF EXISTS `file_thread_lineage_resolve_holder`$
CREATE PROCEDURE `file_thread_lineage_resolve_holder`(
  IN _holder_hub_id VARCHAR(16),
  IN _holder_file_nid VARCHAR(16)
)
BEGIN
  SELECT
    l.lineage_id,
    l.original_hub_id,
    l.original_file_nid,
    l.original_thread_id,
    l.current_hub_id,
    l.current_file_nid,
    l.current_thread_id,
    l.holder_hub_id,
    l.holder_file_nid,
    l.current_operation_id,
    l.access_revision,
    l.state
  FROM file_thread_lineage l
  WHERE l.holder_hub_id = _holder_hub_id
    AND l.holder_file_nid = _holder_file_nid;
END $

DELIMITER ;
