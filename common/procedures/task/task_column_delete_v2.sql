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
  DECLARE _scope VARCHAR(16) CHARACTER SET ascii DEFAULT IFNULL(_nid, '');
  DECLARE _tnid VARCHAR(16) CHARACTER SET ascii DEFAULT NULLIF(IFNULL(_nid, ''), '');

  -- v2 takes the folder scope instead of deriving it from the id. Built-in ids
  -- ('todo', 'complete', ...) are literal status keys that now exist once PER
  -- SCOPE, so the old `WHERE id = _id` would delete that built-in from EVERY
  -- board in the workspace and re-home the wrong tasks.
  --
  -- Two spellings of "root" have to be reconciled: task_column.nid uses ''
  -- (it is part of the primary key and cannot be NULL) while task.nid keeps
  -- NULL. _scope addresses task_column, _tnid addresses task.

  -- Re-home this column's tasks onto the first surviving column of the SAME
  -- scope (board order), so deleting any column — built-in or custom — never
  -- orphans a task.
  SELECT id INTO _fallback
    FROM task_column
   WHERE id <> _id
     AND IFNULL(nid, '') = _scope
   ORDER BY position, ctime
   LIMIT 1;

  IF _fallback IS NOT NULL THEN
    UPDATE task
       SET status = _fallback,
           mtime  = UNIX_TIMESTAMP()
     WHERE status = _id
       AND nid <=> _tnid;
    SET _moved = ROW_COUNT();
  END IF;

  -- A deleted column cannot be watched. Keep the per-user watch table aligned
  -- with the board so a recreated column never inherits stale subscriptions.
  DELETE FROM task_column_watch
   WHERE column_key = _id
     AND nid = IFNULL(NULLIF(_nid, ''), '0');

  DELETE FROM task_column
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;

  SELECT ROW_COUNT() AS affected, _id AS id, _moved AS moved_tasks, _fallback AS moved_to;
END$
DELIMITER ;
