DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_reorder`$
CREATE PROCEDURE `task_column_reorder`(
  IN _nid VARCHAR(16),
  IN _order TEXT
)
BEGIN
  -- Persist a drag-reorder of custom columns. _order is the comma-separated
  -- column ids in their new left-to-right order; each column's position is set
  -- to its index in that list (FIND_IN_SET is 1-based). Scoped to the folder so
  -- one folder's reorder can't touch another's rows.
  UPDATE task_column
     SET position = FIND_IN_SET(id, _order),
         mtime = UNIX_TIMESTAMP()
   WHERE nid <=> _nid
     AND FIND_IN_SET(id, _order) > 0;

  SELECT id, nid, name, theme, position, ctime, mtime
    FROM task_column
   WHERE nid <=> _nid
   ORDER BY position, ctime;
END$
DELIMITER ;
