DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_delete_v2`$
CREATE PROCEDURE `task_column_delete_v2`(
  IN _id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  -- CHARACTER SET ascii to match task_column.nid / task.nid: without it the
  -- variable takes the database default (utf8mb4) and every comparison against
  -- the ascii column raises ER_CANT_AGGREGATE_2COLLATIONS (1267).
  DECLARE _moved INT DEFAULT 0;
  DECLARE _fallback VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  -- WORKSPACE SCOPE: columns live once per workspace, at the root scope ''.
  -- Was IFNULL(_nid, ''), which gave every folder its own column set. The
  -- _nid parameter is kept so the signature (and every caller) is unchanged;
  -- it is simply no longer part of the key.
  DECLARE _scope VARCHAR(16) CHARACTER SET ascii DEFAULT '';

  -- Re-home this column's tasks onto the first surviving column, so deleting
  -- any column — built-in or custom — never orphans a task.
  SELECT id INTO _fallback
    FROM task_column
   WHERE id <> _id
     AND IFNULL(nid, '') = _scope
   ORDER BY position, ctime
   LIMIT 1;

  IF _fallback IS NOT NULL THEN
    -- EVERY task in the column, whatever folder it was created in. This used
    -- to be additionally filtered by `nid <=> _tnid`, back when each folder had
    -- its own copy of a column and only that folder's tasks could point at the
    -- copy being deleted. There is one column set per workspace now, so that
    -- filter would leave most of the column's tasks pointing at an id that no
    -- longer exists — present in the table, absent from the board.
    UPDATE task
       SET status = _fallback,
           mtime  = UNIX_TIMESTAMP()
     WHERE status = _id;
    SET _moved = ROW_COUNT();
  END IF;

  -- A deleted column cannot be watched. Keep the per-user watch table aligned
  -- with the board so a recreated column never inherits stale subscriptions.
  -- '0' is that table's single workspace scope (see task_column_watch_set).
  DELETE FROM task_column_watch
   WHERE column_key = _id
     AND nid = '0';

  DELETE FROM task_column
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;

  SELECT ROW_COUNT() AS affected, _id AS id, _moved AS moved_tasks, _fallback AS moved_to;
END$
DELIMITER ;
