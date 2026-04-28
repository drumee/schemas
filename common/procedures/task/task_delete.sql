DELIMITER $
DROP PROCEDURE IF EXISTS `task_delete`$
CREATE PROCEDURE `task_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  -- Explicitly delete task_file rows first (no FK cascade via LIKE mechanism)
  DELETE FROM task_file WHERE task_id = _id;
  DELETE FROM task WHERE id = _id;
  SELECT ROW_COUNT() AS affected;
END$
DELIMITER ;