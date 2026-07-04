DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_get`$
CREATE PROCEDURE `task_column_get`(
  IN _id VARCHAR(16)
)
BEGIN
  -- Existence/lookup check used by the task service to validate a custom
  -- status key before writing it onto a task.
  SELECT id, nid, name, theme, position, ctime, mtime
    FROM task_column
   WHERE id = _id;
END$
DELIMITER ;
