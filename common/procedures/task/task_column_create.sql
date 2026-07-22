DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_create`$
CREATE PROCEDURE `task_column_create`(
  IN _id VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _name VARCHAR(100),
  IN _theme VARCHAR(20)
)
BEGIN
  DECLARE _pos INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();
  -- '' is the canonical root scope: task_column.nid is part of the primary key
  -- and cannot be NULL. Comparing IFNULL(nid,'') = _sk keeps this correct
  -- whether nid still stores NULL for root (pre alter_task_column_scope_pk) or
  -- '' (post), so the proc is safe to apply before OR after that migration.
  DECLARE _sk VARCHAR(16) DEFAULT IFNULL(_nid, '');

  -- Append to the right end of this folder's columns.
  SELECT IFNULL(MAX(position), 0) + 1 INTO _pos
    FROM task_column
   WHERE IFNULL(nid, '') = _sk;

  INSERT INTO task_column (id, nid, name, theme, position, ctime, mtime)
  VALUES (_id, _sk, _name, IFNULL(_theme, 'default'), _pos, _now, _now);

  -- Scoped: a built-in id exists once per scope, so id alone is ambiguous.
  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE id = _id
     AND IFNULL(nid, '') = _sk;
END$
DELIMITER ;
