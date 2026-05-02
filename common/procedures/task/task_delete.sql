DELIMITER $
DROP PROCEDURE IF EXISTS `task_delete`$
CREATE PROCEDURE `task_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  -- Explicitly delete dependent rows first (no FK cascade)
  DELETE FROM task_file  WHERE task_id = _id;
  DELETE FROM task_label WHERE task_id = _id;
  DELETE FROM task       WHERE id = _id;
  SELECT ROW_COUNT() AS affected;
END$
DELIMITER ;
