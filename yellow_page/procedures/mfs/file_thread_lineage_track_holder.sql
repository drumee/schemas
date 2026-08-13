DELIMITER $

-- =========================================================
-- file_thread_lineage_track_holder
--
-- Follows a file that moves between two hubs while its thread stays home:
-- workspace B -> C, with the thread still in A. The thread's own state does
-- not change (it was unavailable before the hop and still is), only the
-- record of where the file now lives.
--
-- access_revision still advances, because the source-hub UI shows the holding
-- workspace's name on the thread's info card and would otherwise keep naming
-- the hub the file already left.
--
-- Not for the return trip: a file arriving at its home hub goes through
-- file_thread_access_transition_direct with reason 'move_back', which clears
-- holder_* and flips the state back to active.
-- =========================================================
DROP PROCEDURE IF EXISTS `file_thread_lineage_track_holder`$
CREATE PROCEDURE `file_thread_lineage_track_holder`(
  IN _lineage_id VARCHAR(16),
  IN _holder_hub_id VARCHAR(16),
  IN _holder_file_nid VARCHAR(16)
)
main: BEGIN
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS tracked, 'HOLDER_TRACK_FAILED' AS status;
  END;

  IF _holder_hub_id IS NULL OR _holder_file_nid IS NULL THEN
    SELECT 1 AS failed, 0 AS tracked, 'HOLDER_REQUIRED' AS status;
    LEAVE main;
  END IF;

  START TRANSACTION;

  -- Only a thread that is already away can change hands. Requiring
  -- 'unavailable' keeps this from silently rewriting the holder of a thread
  -- whose file is home, or one already orphaned.
  UPDATE file_thread_lineage
  SET holder_hub_id = _holder_hub_id,
      holder_file_nid = _holder_file_nid,
      access_revision = access_revision + 1,
      mtime = _now
  WHERE lineage_id = _lineage_id
    AND state = 'unavailable'
    AND current_operation_id IS NULL;

  SET _changed = ROW_COUNT();
  COMMIT;

  SELECT 0 AS failed, _changed AS tracked,
    IF(_changed = 1, 'TRACKED', 'HOLDER_CAS_MISMATCH') AS status,
    lineage_id, current_hub_id, current_thread_id,
    holder_hub_id, holder_file_nid, access_revision, state
  FROM file_thread_lineage WHERE lineage_id = _lineage_id;
END $

DELIMITER ;
