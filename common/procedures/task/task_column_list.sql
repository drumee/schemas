DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_list`$
CREATE PROCEDURE `task_column_list`(
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _init INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();
  DECLARE _sk VARCHAR(16) DEFAULT IFNULL(_nid, '');

  -- Initialize-once: the FIRST time a folder scope's board is opened, seed the
  -- four built-in columns as real rows so every board always starts with the
  -- defaults. The scope is then recorded in task_column_init and never seeded
  -- again — so the user's renames / recolours / reorders / DELETES all persist
  -- (a deleted built-in must NOT come back on the next open). Their ids ARE the
  -- canonical status keys, so pre-existing tasks still match; 'complete' is
  -- flagged is_done = 1 so completion tracking follows the column, not a label.
  -- _sk is the canonical scope spelling: '' for the workspace root, matching
  -- task_column_init.scope_key and task_column.nid (which is part of the
  -- primary key and so cannot be NULL). Comparing IFNULL(nid,'') = _sk keeps
  -- this correct whether nid still stores NULL for root (pre
  -- alter_task_column_scope_pk) or '' (post), so the proc is safe to apply
  -- before OR after that migration.
  SELECT COUNT(*) INTO _init FROM task_column_init WHERE scope_key = _sk;
  IF _init = 0 THEN
    -- Make room so the built-ins lead any columns a folder already had.
    UPDATE task_column SET position = position + 4 WHERE IFNULL(nid, '') = _sk;
    INSERT IGNORE INTO task_column (id, nid, name, theme, position, is_done, ctime, mtime) VALUES
      ('todo',        _sk, 'To do',       'default', 0, 0, _now, _now),
      ('in_progress', _sk, 'In progress', 'purple',  1, 0, _now, _now),
      ('to_review',   _sk, 'To review',   'orange',  2, 0, _now, _now),
      ('complete',    _sk, 'Complete',    'green',   3, 1, _now, _now);
    INSERT INTO task_column_init (scope_key, ctime) VALUES (_sk, _now);
  END IF;

  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE IFNULL(nid, '') = _sk
   ORDER BY position, ctime;
END$
DELIMITER ;
