DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_get_v2`$
CREATE PROCEDURE `task_column_get_v2`(
  IN _id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  -- CHARACTER SET ascii to match task_column.nid: without it the variable takes
  -- the database default (utf8mb4) and comparing it against the ascii column
  -- raises ER_CANT_AGGREGATE_2COLLATIONS (1267).
  DECLARE _scope VARCHAR(16) CHARACTER SET ascii DEFAULT IFNULL(_nid, '');

  -- Existence/lookup check used by the task service to validate a status key
  -- and to read its is_done flag (completion is column-driven).
  --
  -- v2 takes the folder scope: built-in ids ('todo', 'complete', ...) are
  -- literal status keys that now exist once PER SCOPE, so id alone is
  -- ambiguous and would return one row per board.
  --
  -- IFNULL on BOTH sides so this behaves identically whether task_column.nid
  -- still stores NULL for the root scope (pre alter_task_column_scope_pk) or
  -- '' (post) — the proc is therefore safe to apply before OR after that
  -- migration. task_column holds a handful of rows per DB, so losing idx_nid
  -- here is immaterial.
  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;
END$
DELIMITER ;
