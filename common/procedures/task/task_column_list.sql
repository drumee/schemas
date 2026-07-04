DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_list`$
CREATE PROCEDURE `task_column_list`(
  IN _nid VARCHAR(16)
)
BEGIN
  -- Custom columns for one folder scope, in board order. Built-in columns are
  -- implicit client-side and always precede these.
  SELECT id, nid, name, theme, position, ctime, mtime
    FROM task_column
   WHERE nid <=> _nid
   ORDER BY position, ctime;
END$
DELIMITER ;
