CREATE TABLE IF NOT EXISTS task (
  id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  title varchar(500) NOT NULL,
  description text DEFAULT NULL,
  status enum('todo','in_progress','to_review','complete') NOT NULL DEFAULT 'todo',
  priority enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  due_date date DEFAULT NULL,
  created_by varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- Legacy single-assignee column. Superseded by the task_assignee join table
  -- (multi-assignee). Kept for backward compat; no longer written by the SPs.
  assignee_uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Folder/node scope: media node id of the folder the task belongs to.
  -- NULL = legacy / workspace-level task (surfaces at the workspace root view).
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  rank int(11) NOT NULL DEFAULT 0,
  ctime int(11) NOT NULL DEFAULT 0,
  mtime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_status (status),
  KEY idx_priority (priority),
  KEY idx_created_by (created_by),
  KEY idx_assignee_uid (assignee_uid),
  KEY idx_nid (nid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
