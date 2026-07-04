DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_delete`$
CREATE PROCEDURE `task_column_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _moved INT DEFAULT 0;

  -- Tasks living in the deleted column fall back to the built-in 'todo'
  -- column (never lose tasks). Report how many moved so the client can
  -- refresh its task list when non-zero.
  UPDATE task
     SET status = 'todo',
         mtime  = UNIX_TIMESTAMP()
   WHERE status = _id;
  SET _moved = ROW_COUNT();

  DELETE FROM task_column WHERE id = _id;

  SELECT ROW_COUNT() AS affected, _id AS id, _moved AS moved_tasks;
END$
DELIMITER ;
