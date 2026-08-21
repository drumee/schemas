DELIMITER $

-- =========================================================
-- file_thread_access_transition_direct
--
-- Applies the durable half of a file-thread access change: the thread row
-- itself never moves, only its reachability state does.
--
-- Four reasons, two shapes:
--   direct_trash / direct_restore  the file leaves its hub's media table for
--                                  trash_media, and comes back from it
--   move_out     / move_back       the file crosses to another hub and back
--
-- The trash pair leaves holder_* NULL: nothing left the hub. The move pair
-- writes holder_* (move_out) or clears it (move_back), which is how a later
-- move knows whether an arriving file is coming home or merely passing
-- through a third workspace.
--
-- _holder_hub_id / _holder_file_nid describe where the FILE ended up and are
-- read only for move_out. Every other reason ignores them.
-- =========================================================
DROP PROCEDURE IF EXISTS `file_thread_access_transition_direct`$
CREATE PROCEDURE `file_thread_access_transition_direct`(
  IN _transition_id VARCHAR(16),
  IN _lineage_id VARCHAR(16),
  IN _actor_id VARCHAR(16),
  IN _hub_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _thread_id VARCHAR(16),
  IN _target_state VARCHAR(16),
  IN _reason VARCHAR(32),
  IN _holder_hub_id VARCHAR(16),
  IN _holder_file_nid VARCHAR(16),
  IN _file_name VARCHAR(255)
)
main: BEGIN
  DECLARE _db_name VARCHAR(90) DEFAULT NULL;
  DECLARE _effective_lineage_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_state VARCHAR(16) DEFAULT NULL;
  DECLARE _current_operation_id VARCHAR(16) DEFAULT NULL;
  DECLARE _revision BIGINT UNSIGNED DEFAULT 0;
  DECLARE _expected_state VARCHAR(16);
  DECLARE _is_move TINYINT(1) DEFAULT 0;
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS transitioned, 'DIRECT_TRANSITION_FAILED' AS status;
  END;

  IF _target_state NOT IN ('active','unavailable')
     OR _reason NOT IN ('direct_trash','direct_restore','move_out','move_back') THEN
    SELECT 1 AS failed, 0 AS transitioned, 'INVALID_DIRECT_TRANSITION' AS status;
    LEAVE main;
  END IF;

  -- Reason and target state must agree. Without this a caller could pass
  -- ('active','move_out') and quietly clear holder_* on a thread whose file
  -- is still away.
  IF (_reason IN ('direct_trash','move_out') AND _target_state <> 'unavailable')
     OR (_reason IN ('direct_restore','move_back') AND _target_state <> 'active') THEN
    SELECT 1 AS failed, 0 AS transitioned, 'REASON_STATE_MISMATCH' AS status;
    LEAVE main;
  END IF;

  SET _is_move = IF(_reason IN ('move_out','move_back'), 1, 0);

  IF _reason = 'move_out'
     AND (_holder_hub_id IS NULL OR _holder_file_nid IS NULL) THEN
    SELECT 1 AS failed, 0 AS transitioned, 'HOLDER_REQUIRED' AS status;
    LEAVE main;
  END IF;

  SELECT db_name INTO _db_name FROM entity WHERE id = _hub_id LIMIT 1;
  IF _db_name IS NULL THEN
    SELECT 1 AS failed, 0 AS transitioned, 'HUB_NOT_FOUND' AS status;
    LEAVE main;
  END IF;

  START TRANSACTION;

  SET @_direct_media_id = NULL;
  SET @_direct_thread_id = NULL;
  SET @st = CONCAT('SELECT id INTO @_direct_media_id FROM `',
    REPLACE(_db_name, '`', '``'), '`.media WHERE id = ? LIMIT 1 FOR UPDATE');
  PREPARE stmt FROM @st;
  EXECUTE stmt USING _file_nid;
  DEALLOCATE PREPARE stmt;

  SET @st = CONCAT('SELECT root_message_id INTO @_direct_thread_id FROM `',
    REPLACE(_db_name, '`', '``'),
    '`.file_thread WHERE file_nid = ? AND root_message_id = ? ',
    'AND status = ''active'' LIMIT 1 FOR UPDATE');
  PREPARE stmt FROM @st;
  EXECUTE stmt USING _file_nid, _thread_id;
  DEALLOCATE PREPARE stmt;

  -- The thread row must exist in the home hub for every reason: that row is
  -- the thing whose reachability is being changed. It survives a trash — only
  -- the media row is taken away — so it is checked unconditionally.
  IF @_direct_thread_id IS NULL THEN
    ROLLBACK;
    SELECT 0 AS failed, 0 AS transitioned, 'DURABLE_STATE_MISMATCH' AS status;
    LEAVE main;
  END IF;

  -- Every reason here runs AFTER its file operation committed, so each one
  -- asserts the state that operation was supposed to leave behind.
  --
  -- Trashing does not hide the media row, it removes it: mfs_pre_trash_next
  -- copies the subtree into trash_media and then runs
  --   DELETE FROM <hub_db>.media WHERE id IN (SELECT id FROM _mytree)
  -- (mfs-trash/mfs_pre_trash.sql:139). So after direct_trash the row must be
  -- GONE, exactly as after move_out. Requiring it to be present was a
  -- misreading of that procedure, and it made every direct_trash transition
  -- fail closed with DURABLE_STATE_MISMATCH — no event reached any client, so
  -- deleting a file silently stopped closing the threads that discussed it.
  --
  -- Restoring is the mirror: mfs_restore INSERTs the row back into media
  -- (mfs/restore.sql:55) before this runs, so it must be present again — which
  -- is why direct_restore kept working throughout and direct_trash never did.
  IF (_reason = 'direct_trash' AND @_direct_media_id IS NOT NULL)
     OR (_reason = 'direct_restore' AND @_direct_media_id IS NULL)
     OR (_reason = 'move_out' AND @_direct_media_id IS NOT NULL)
     OR (_reason = 'move_back' AND @_direct_media_id IS NULL) THEN
    ROLLBACK;
    SELECT 0 AS failed, 0 AS transitioned, 'DURABLE_STATE_MISMATCH' AS status;
    LEAVE main;
  END IF;

  -- Locate by file position, which carries a UNIQUE index; (hub, thread) does
  -- not, and stage data shows why it cannot be trusted as a key: two rows
  -- there share a thread id, one of them left behind by a failed move whose
  -- current_file_nid no longer exists in media. Keying on the thread would
  -- pick between them by luck.
  --
  -- move_back is the exception, and has to be: the file comes back as a NEW
  -- node, so _file_nid matches nothing yet. It resolves through the holder_*
  -- pair instead — the record of where the file has been living — which is
  -- exactly the row that should now come home.
  IF _reason = 'move_back' THEN
    -- Keyed on the lineage id, which the caller already resolved through
    -- holder_*. Matching on (hub, thread) instead would be ambiguous now that
    -- one file can be tracked by several threads in different workspaces.
    --
    -- 'orphaned' is matched here too, though it can never succeed: without it
    -- the row simply would not resolve and the caller would be told
    -- LINEAGE_NOT_TRACKED — "no such thread" — when the truth is "that thread's
    -- file was deleted". Both refuse the move; only one is debuggable.
    SELECT lineage_id, state, current_operation_id, access_revision
      INTO _effective_lineage_id, _current_state, _current_operation_id, _revision
    FROM file_thread_lineage
    WHERE lineage_id = _lineage_id
      AND current_hub_id = _hub_id
      AND current_thread_id = _thread_id
      AND state IN ('unavailable','orphaned')
      AND holder_hub_id IS NOT NULL
    LIMIT 1 FOR UPDATE;
  ELSE
    -- Thread first, file position second, matching reserve. The reservation
    -- re-points current_file_nid at the node the file is on now, so a lookup
    -- that insisted on the caller's nid would miss the very row it reserved
    -- once the file had moved before.
    SELECT lineage_id, state, current_operation_id, access_revision
      INTO _effective_lineage_id, _current_state, _current_operation_id, _revision
    FROM file_thread_lineage
    WHERE current_hub_id = _hub_id AND current_thread_id = _thread_id
    ORDER BY (current_file_nid = _file_nid) DESC, mtime DESC
    LIMIT 1 FOR UPDATE;

    IF _effective_lineage_id IS NULL THEN
      SELECT lineage_id, state, current_operation_id, access_revision
        INTO _effective_lineage_id, _current_state, _current_operation_id, _revision
      FROM file_thread_lineage
      WHERE current_hub_id = _hub_id AND current_file_nid = _file_nid
      LIMIT 1 FOR UPDATE;
    END IF;
  END IF;

  IF _effective_lineage_id IS NULL THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned,
      IF(_target_state = 'active', 'LINEAGE_NOT_TRACKED', 'RESERVATION_REQUIRED') AS status;
    LEAVE main;
  END IF;

  IF _current_state = _target_state THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned, 'ALREADY_APPLIED' AS status,
      lineage_id, last_transition_id AS transition_id, access_revision
    FROM file_thread_lineage WHERE lineage_id = _effective_lineage_id;
    LEAVE main;
  END IF;

  -- A thread that went 'orphaned' has no way back: the file it described was
  -- permanently deleted.
  IF _current_state = 'orphaned' THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned, 'LINEAGE_ORPHANED' AS status,
      _effective_lineage_id AS lineage_id, _revision AS access_revision;
    LEAVE main;
  END IF;

  IF (_target_state = 'unavailable'
      AND (_current_state <> 'moving' OR _current_operation_id <> _transition_id))
     OR (_target_state = 'active'
      AND (_current_state <> 'unavailable' OR _current_operation_id IS NOT NULL)) THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned,
      IF(_current_operation_id IS NOT NULL, 'LINEAGE_MOVING', 'DIRECT_STATE_CONFLICT') AS status,
      _effective_lineage_id AS lineage_id, _revision AS access_revision;
    LEAVE main;
  END IF;

  SET _expected_state = IF(_target_state = 'active', 'unavailable', 'moving');

  -- move_back is the one reason that changes current_file_nid: a returning
  -- file is a brand-new node (mfs_create_node), so the thread must be
  -- re-pointed at it, exactly as channel_file_thread_rebind_returned_file
  -- already re-points the file_thread row. Every other reason leaves the
  -- file where it was, so current_file_nid both matches on the way in and
  -- stays untouched on the way out.
  UPDATE file_thread_lineage
  SET state = _target_state,
      current_file_nid = IF(_reason = 'move_back', _file_nid, current_file_nid),
      holder_hub_id = CASE
        WHEN _is_move = 0 THEN holder_hub_id
        WHEN _reason = 'move_out' THEN _holder_hub_id
        ELSE NULL END,
      holder_file_nid = CASE
        WHEN _is_move = 0 THEN holder_file_nid
        WHEN _reason = 'move_out' THEN _holder_file_nid
        ELSE NULL END,
      -- Captured on the way out, because the media row that held the name is
      -- already gone by then. Kept on the way back rather than cleared: the
      -- file is present again, so its own row supplies the name, and keeping
      -- the last known one costs nothing if it leaves again.
      file_name = CASE
        WHEN _reason = 'move_out' AND _file_name IS NOT NULL THEN _file_name
        ELSE file_name END,
      current_operation_id = NULL,
      last_transition_id = _transition_id,
      last_transition_reason = _reason,
      access_revision = access_revision + 1,
      mtime = _now
  WHERE lineage_id = _effective_lineage_id
    AND current_hub_id = _hub_id
    AND current_thread_id = _thread_id
    -- current_file_nid is deliberately absent from this CAS. move_back carries
    -- the new node id by design, and every other reason may be acting on a
    -- lineage whose current_file_nid reserve has already advanced to the node
    -- the file is on now. lineage_id above pins the exact row; the state and
    -- operation-id predicates below are untouched, so only the operation
    -- holding the reservation can transition it.
    AND ((_target_state = 'unavailable' AND current_operation_id = _transition_id)
      OR (_target_state = 'active' AND current_operation_id IS NULL))
    AND state = _expected_state;

  SET _changed = ROW_COUNT();
  COMMIT;

  SELECT 0 AS failed, _changed AS transitioned,
    IF(_changed = 1, 'APPLIED', 'CAS_MISMATCH') AS status,
    lineage_id, last_transition_id AS transition_id, access_revision,
    holder_hub_id, holder_file_nid, state
  FROM file_thread_lineage WHERE lineage_id = _effective_lineage_id;
END $

DELIMITER ;
