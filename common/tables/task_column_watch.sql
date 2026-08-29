CREATE TABLE IF NOT EXISTS task_column_watch (
  uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- Always '0'. Columns are workspace-level (see
  -- alter_task_column_workspace_scope), so a watch is too; the procs hard-code
  -- this value. The column stays in the PRIMARY KEY rather than being dropped —
  -- removing it would mean rebuilding the key on every live database for no
  -- gain, and it keeps the door open if scoping ever returns.
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '0',
  -- Either a built-in status string ('todo', 'in_progress', …) or a custom
  -- task_column.id. No FK — built-ins have no task_column row.
  column_key varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  ctime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (uid, nid, column_key),
  KEY idx_col (nid, column_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
