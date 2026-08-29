DELIMITER $

DROP PROCEDURE IF EXISTS `task_column_set_done`$
CREATE PROCEDURE `task_column_set_done`(
  IN _id VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _is_done TINYINT(1)
)
BEGIN
  -- CHARACTER SET ascii to match task_column.nid: without it the variable takes
  -- the database default (utf8mb4) and comparing it against the ascii column
  -- raises ER_CANT_AGGREGATE_2COLLATIONS (1267). Same reason as
  -- task_column_update_v2.
  -- WORKSPACE SCOPE: columns live once per workspace, at the root scope ''.
  -- Was IFNULL(_nid, ''), which gave every folder its own column set. The
  -- _nid parameter is kept so the signature (and every caller) is unchanged;
  -- it is simply no longer part of the key.
  DECLARE _scope VARCHAR(16) CHARACTER SET ascii DEFAULT '';

  -- Flip a column's "tasks in here are done" flag. is_done already drives
  -- completed_at stamping (task_update_status), the subtask done/total badge
  -- (task_list.subtask_done) and the Project Health stats; the flag existed on
  -- every board since alter_task_column_add_is_done.sql, but nothing could SET
  -- it, so only the seeded built-in 'complete' was ever a done column. A board
  -- that renamed its columns (Reopen / Prepare to release / Released) had no
  -- way to say which one means finished.
  --
  -- A SEPARATE, ADDITIVE routine on purpose: adding a fourth parameter to
  -- task_column_create / task_column_update_v2 would be a breaking signature
  -- change and would force a _vN rename of a proc that many callers already
  -- use. This one only ever writes is_done.
  --
  -- Folder-scoped for the same reason as task_column_update_v2: built-in ids
  -- ARE literal status keys stored once PER SCOPE, so keying on id alone would
  -- flag that column on EVERY board in the workspace. IFNULL on both sides so
  -- this is correct whether task_column.nid still stores NULL for the root
  -- scope (pre alter_task_column_scope_pk) or '' (post).
  --
  -- Any number of columns on a board may be done columns — the client reads
  -- them as a SET (_doneKeys), and a board that wants both "To review" and
  -- "Released" to count as finished is legitimate. So this never clears the
  -- other rows.
  UPDATE task_column
     SET is_done = IF(IFNULL(_is_done, 0) = 0, 0, 1),
         mtime   = UNIX_TIMESTAMP()
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;

  -- Same shape as task_column_update_v2 so the client can reuse one row
  -- handler. An empty result means no such column in this scope, which is how
  -- the service raises COLUMN_NOT_FOUND (the DB layer swallows SQL errors, so
  -- the returned rows are the only failure signal available).
  SELECT id, nid, name, theme, position, is_done, ctime, mtime
    FROM task_column
   WHERE id = _id
     AND IFNULL(nid, '') = _scope;
END$

DELIMITER ;
