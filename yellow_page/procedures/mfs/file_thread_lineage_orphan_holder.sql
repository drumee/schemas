DELIMITER $

-- =========================================================
-- file_thread_lineage_orphan_holder
--
-- Called when a file is permanently deleted in whichever hub was holding it —
-- a workspace it had moved to, or its own, since a file waits out its time in
-- the bin at home.
--
-- Every thread waiting on that file is affected, not just one. A file can be
-- discussed in several workspaces — each keeps its own thread, all of them
-- pointing at the same absent file — and deleting the file ends the wait for
-- all of them equally. Threads stay readable in their own workspaces; they
-- simply stop expecting anything back.
--
-- Deliberately not called for trash itself: a trashed file can be restored,
-- and the threads should keep waiting. Only emptying the bin comes through
-- here.
--
-- Returns one row per thread it orphaned, carrying current_hub_id and
-- current_thread_id so the caller can address an access-changed event to each
-- home workspace — never the workspace where the deletion happened.
-- =========================================================
DROP PROCEDURE IF EXISTS `file_thread_lineage_orphan_holder`$
CREATE PROCEDURE `file_thread_lineage_orphan_holder`(
  IN _transition_id VARCHAR(16),
  IN _holder_hub_id VARCHAR(16),
  IN _holder_file_nid VARCHAR(16)
)
main: BEGIN
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS orphaned, 'ORPHAN_FAILED' AS status;
  END;

  START TRANSACTION;

  DROP TEMPORARY TABLE IF EXISTS _orphan_targets;
  CREATE TEMPORARY TABLE _orphan_targets (
    lineage_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    PRIMARY KEY (lineage_id)
  ) ENGINE=MEMORY;

  -- Two ways a thread can be waiting on the file being deleted, and both end
  -- here.
  --
  -- holder_* is the away case: the file moved to another workspace and the
  -- thread stayed home, so the lineage records where the file went and the
  -- deletion happens over there.
  --
  -- The second case is the file that never left. Trashing it marks the lineage
  -- unavailable while leaving holder_* NULL — nothing is holding it elsewhere,
  -- it is in its own workspace's bin. Emptying that bin deletes it for good.
  -- Matching only on holder_* missed those entirely (NULL = X is never true),
  -- so the lineage stayed 'unavailable' forever: the thread kept refusing to
  -- reopen, its card claimed the file had been "moved to another workspace",
  -- and reserve — which requires 'active' — could never take it again.
  INSERT INTO _orphan_targets (lineage_id)
  SELECT lineage_id
  FROM file_thread_lineage
  WHERE state = 'unavailable'
    AND current_operation_id IS NULL
    AND (
      (holder_hub_id = _holder_hub_id AND holder_file_nid = _holder_file_nid)
      OR (holder_hub_id IS NULL
          AND current_hub_id = _holder_hub_id
          AND current_file_nid = _holder_file_nid)
    )
  FOR UPDATE;

  -- No thread anywhere is waiting on this file. Deleting a file is by far the
  -- common case, so this is an ordinary outcome, not a failure.
  IF (SELECT COUNT(*) FROM _orphan_targets) = 0 THEN
    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS _orphan_targets;
    SELECT 0 AS failed, 0 AS orphaned, 'NO_LINEAGE' AS status;
    LEAVE main;
  END IF;

  -- last_transition_id is UNIQUE, so several rows cannot share one id. Each
  -- gets the caller's id suffixed by its own lineage, keeping the column
  -- meaningful (which operation touched this row) without collisions.
  UPDATE file_thread_lineage l
  INNER JOIN _orphan_targets t ON t.lineage_id = l.lineage_id
  SET l.state = 'orphaned',
      l.last_transition_id = LEFT(CONCAT(LEFT(_transition_id, 8), l.lineage_id), 16),
      l.last_transition_reason = 'orphaned',
      l.access_revision = l.access_revision + 1,
      l.mtime = _now
  WHERE l.state = 'unavailable'
    AND l.current_operation_id IS NULL;

  SET _changed = ROW_COUNT();
  COMMIT;

  SELECT 0 AS failed, _changed AS orphaned,
    IF(_changed > 0, 'ORPHANED', 'ORPHAN_CAS_MISMATCH') AS status,
    l.lineage_id, l.current_hub_id, l.current_file_nid, l.current_thread_id,
    l.holder_hub_id, l.holder_file_nid, l.access_revision, l.state
  FROM file_thread_lineage l
  INNER JOIN _orphan_targets t ON t.lineage_id = l.lineage_id;

  DROP TEMPORARY TABLE IF EXISTS _orphan_targets;
END $

DELIMITER ;
