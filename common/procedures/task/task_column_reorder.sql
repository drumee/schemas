DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_reorder`$
CREATE PROCEDURE `task_column_reorder`(
  IN _nid VARCHAR(16),
  IN _order TEXT
)
BEGIN
  -- '' is the canonical root scope: task_column.nid is part of the primary key
  -- and cannot be NULL. Comparing IFNULL(nid,'') = _sk keeps this correct
  -- whether nid still stores NULL for root (pre alter_task_column_scope_pk) or
  -- '' (post), so the proc is safe to apply before OR after that migration.
  DECLARE _sk VARCHAR(16) DEFAULT IFNULL(_nid, '');

  -- Persist a drag-reorder of the board's columns. _order is the comma-separated
  -- column ids in their new left-to-right order; each column's position is set
  -- to its index in that list (FIND_IN_SET is 1-based). Scoped to the folder so
  -- one folder's reorder can't touch another's rows — which matters more now
  -- that built-in ids are shared across scopes.
  UPDATE task_column
     SET position = FIND_IN_SET(id, _order),
         mtime = UNIX_TIMESTAMP()
   WHERE IFNULL(nid, '') = _sk
     AND FIND_IN_SET(id, _order) > 0;

  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE IFNULL(nid, '') = _sk
   ORDER BY position, ctime;
END$
DELIMITER ;
