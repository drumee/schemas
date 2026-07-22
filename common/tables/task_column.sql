-- Kanban columns, folder-scoped like tasks (nid = media node id of the folder;
-- '' = workspace root). Holds BOTH the four built-in columns (todo,
-- in_progress, to_review, complete — seeded per scope on a board's first open
-- by task_column_list) and user-created ones, so built-ins can be renamed,
-- recoloured, reordered and deleted like any other column. A column's id
-- doubles as the task.status value for tasks placed in it.
--
-- The key is (id, nid): built-in ids ARE literal status keys, so the same id
-- must be able to exist once PER SCOPE. Keying on id alone let only the first
-- scope opened hold them — every later scope's INSERT IGNORE silently hit the
-- collision and stored nothing (see patches/alter_task_column_scope_pk.sql).
--
-- nid is NOT NULL because a PRIMARY KEY column cannot hold NULL; the root
-- scope is '' here, matching task_column_init.scope_key. NOTE task.nid keeps
-- NULL for root, so the procs map between the two with IFNULL/NULLIF.
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
