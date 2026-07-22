CREATE TABLE IF NOT EXISTS task_column_watch (
  uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- Folder scope. '0' = workspace root (built-in column keys like 'todo' are
  -- only unique within a folder, so the watch must be folder-scoped).
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '0',
  -- Either a built-in status string ('todo', 'in_progress', …) or a custom
  -- task_column.id. No FK — built-ins have no task_column row.
  column_key varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  ctime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (uid, nid, column_key),
  KEY idx_col (nid, column_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
