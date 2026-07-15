DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_update`$
CREATE PROCEDURE `task_column_update`(
  IN _id VARCHAR(16),
  IN _name VARCHAR(100),
  IN _theme VARCHAR(20)
)
BEGIN
  -- NULL keeps the existing value (rename and recolor are independent).
  UPDATE task_column
     SET name  = IFNULL(_name, name),
         theme = IFNULL(_theme, theme),
         mtime = UNIX_TIMESTAMP()
   WHERE id = _id;

  SELECT id, nid, name, theme, position, ctime, mtime
    FROM task_column
   WHERE id = _id;
END$
DELIMITER ;
