-- Custom Kanban columns, folder-scoped like tasks (nid = media node id of the
-- folder; NULL = workspace root). The four built-in columns (todo, in_progress,
-- to_review, complete) are implicit client-side and are NOT stored here — only
-- user-created columns are. A custom column's id doubles as the task.status
-- value for tasks placed in it.
CREATE TABLE IF NOT EXISTS task_column (
  id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  name varchar(100) NOT NULL,
  -- Visual theme key from the 10-swatch palette (Figma 2040-106090):
  -- default | orange | yellow | green | cyan | blue | purple | pink | red
  theme varchar(20) NOT NULL DEFAULT 'default',
  position int(11) NOT NULL DEFAULT 0,
  ctime int(11) NOT NULL DEFAULT 0,
  mtime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_nid (nid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
