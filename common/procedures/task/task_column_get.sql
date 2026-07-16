DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_get`$
CREATE PROCEDURE `task_column_get`(
  IN _id VARCHAR(16)
)
BEGIN
  -- Existence/lookup check used by the task service to validate a status key
  -- and to read its is_done flag (completion is column-driven).
  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE id = _id;
END$
DELIMITER ;
