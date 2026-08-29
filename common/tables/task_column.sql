-- Kanban columns. ONE SET PER WORKSPACE: every row sits at nid = '' and every
-- proc hard-codes that scope (see patches/alter_task_column_workspace_scope).
-- A board is the workspace's board, so its columns are the workspace's too.
--
-- Holds BOTH the four built-in columns (todo, in_progress, to_review, complete
-- — seeded on the board's first open by task_column_list) and user-created
-- ones, so built-ins can be renamed, recoloured, reordered and deleted like any
-- other column. A column's id doubles as the task.status value for tasks
-- placed in it.
--
-- nid survives as a column and stays in the PRIMARY KEY, holding '' on every
-- row. It was the folder scope while columns were per-folder
-- (alter_task_column_scope_pk added it to the key for exactly that); rebuilding
-- the key on every live database to remove it buys nothing, and keeping it
-- leaves the door open if scoping ever returns. NOTE task.nid still records the
-- folder a task was created in — provenance, not scope.
CREATE TABLE IF NOT EXISTS task_column (
  id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  name varchar(100) NOT NULL,
  -- Visual theme key from the 10-swatch palette (Figma 2040-106090):
  -- default | orange | yellow | green | cyan | blue | purple | pink | red
  theme varchar(20) NOT NULL DEFAULT 'default',
  position int(11) NOT NULL DEFAULT 0,
  is_done tinyint(1) NOT NULL DEFAULT 0,
  ctime int(11) NOT NULL DEFAULT 0,
  mtime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id, nid),
  KEY idx_nid (nid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
