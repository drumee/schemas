DELIMITER $

DROP PROCEDURE IF EXISTS `file_thread_access_release_direct`$
CREATE PROCEDURE `file_thread_access_release_direct`(
  IN _transition_id VARCHAR(16),
  IN _hub_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _thread_id VARCHAR(16)
)
main: BEGIN
  DECLARE _db_name VARCHAR(90) DEFAULT NULL;
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS released, 'DIRECT_RELEASE_FAILED' AS status;
  END;

  SELECT db_name INTO _db_name FROM entity WHERE id = _hub_id LIMIT 1;
  IF _db_name IS NULL THEN
    SELECT 1 AS failed, 0 AS released, 'HUB_NOT_FOUND' AS status;
    LEAVE main;
  END IF;

  START TRANSACTION;

  -- Deliberately NOT gated on the media or thread row still being present.
  --
  -- Release is the undo half of reserve, and its worst case is a cross-hub
  -- move: reserve runs while the file is still here, then mfs_move_all DELETEs
  -- the media row and channel_migrate_moved_scope DELETEs the source
  -- file_thread. If the move_out transition then fails, this is the only path
  -- left that can hand the reservation back — and both rows it used to check
  -- are already gone. Refusing there parked the lineage in 'moving' forever,
  -- blocking every later move of that thread.
  --
  -- Nothing is lost by dropping the check: the UPDATE below is keyed on
  -- current_operation_id = _transition_id, so only the operation that took
  -- this reservation can clear it, whatever state the file is in.

  -- current_file_nid is deliberately not matched: reserve re-points it at the
  -- node the file is on now, and a caller releasing after a failed move still
  -- holds the id it started with. current_operation_id is the reservation
  -- token and is unique to this operation, so it alone is enough to identify
  -- the row safely.
  UPDATE file_thread_lineage
  SET state = 'active', current_operation_id = NULL, mtime = _now
  WHERE current_hub_id = _hub_id
    AND current_thread_id = _thread_id
    AND current_operation_id = _transition_id
    AND state = 'moving';

  SET _changed = ROW_COUNT();
  COMMIT;

  SELECT 0 AS failed, _changed AS released,
    IF(_changed = 1, 'RELEASED', 'RESERVATION_NOT_FOUND') AS status;
END $

DELIMITER ;
