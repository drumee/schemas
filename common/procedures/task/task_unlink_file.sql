DELIMITER $
DROP PROCEDURE IF EXISTS `task_unlink_file`$
CREATE PROCEDURE `task_unlink_file`(
  IN _task_id VARCHAR(16),
  IN _file_nid VARCHAR(16)
)
BEGIN
  DELETE FROM task_file
   WHERE task_id  = _task_id
     AND file_nid = _file_nid;

  SELECT ROW_COUNT() AS affected;
END$
DELIMITER ;