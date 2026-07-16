DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_delete`$
CREATE PROCEDURE `task_column_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _moved INT DEFAULT 0;
  DECLARE _nid VARCHAR(16) DEFAULT NULL;
  DECLARE _fallback VARCHAR(16) DEFAULT NULL;

  SELECT nid INTO _nid FROM task_column WHERE id = _id;

  -- Re-home this column's tasks onto the first surviving column of the SAME
  -- scope (board order), so deleting any column — built-in or custom — never
  -- orphans a task. (Previously tasks were force-moved to the literal 'todo';
  -- that breaks once 'todo' itself is deletable.)
  SELECT id INTO _fallback
    FROM task_column
   WHERE id <> _id AND nid <=> _nid
   ORDER BY position, ctime
   LIMIT 1;

  IF _fallback IS NOT NULL THEN
    UPDATE task
       SET status = _fallback,
           mtime  = UNIX_TIMESTAMP()
     WHERE status = _id AND nid <=> _nid;
    SET _moved = ROW_COUNT();
  END IF;

  DELETE FROM task_column WHERE id = _id;

  SELECT ROW_COUNT() AS affected, _id AS id, _moved AS moved_tasks, _fallback AS moved_to;
END$
DELIMITER ;
