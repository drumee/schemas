DELIMITER $
DROP PROCEDURE IF EXISTS `task_unlink_label`$
CREATE PROCEDURE `task_unlink_label`(
  IN _task_id VARCHAR(16),
  IN _label_id VARCHAR(16)
)
BEGIN
  DELETE FROM task_label
   WHERE task_id  = _task_id
     AND label_id = _label_id;

  SELECT ROW_COUNT() AS affected;
END$
DELIMITER ;
