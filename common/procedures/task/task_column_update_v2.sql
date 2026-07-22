DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_update_v2`$
CREATE PROCEDURE `task_column_update_v2`(
  IN _id VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _name VARCHAR(100),
  IN _theme VARCHAR(20)
)
BEGIN
  -- CHARACTER SET ascii to match task_column.nid: without it the variable takes
  -- the database default (utf8mb4) and comparing it against the ascii column
  -- raises ER_CANT_AGGREGATE_2COLLATIONS (1267).
  DECLARE _scope VARCHAR(16) CHARACTER SET ascii DEFAULT IFNULL(_nid, '');

  -- NULL keeps the existing value (rename and recolor are independent).
  --
  -- v2 takes the folder scope. Built-in ids ('todo', 'complete', ...) are
  -- literal status keys that now exist once PER SCOPE, so keying on id alone
  -- would rename/recolour that built-in on EVERY board in the workspace.
  --
  -- IFNULL on both sides so this is correct whether task_column.nid still
  -- stores NULL for the root scope (pre alter_task_column_scope_pk) or ''
  -- (post) — safe to apply before OR after that migration.
  UPDATE task_column
     SET name  = IFNULL(_name, name),
         theme = IFNULL(_theme, theme),
         mtime = UNIX_TIMESTAMP()
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;

  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;
END$
DELIMITER ;
