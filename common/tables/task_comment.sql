CREATE TABLE IF NOT EXISTS task_comment (
  id         varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  task_id    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  author_uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- Root comment id for a reply; NULL for a top-level comment (1-level threads).
  parent_id  varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Marker form: "[@Full Name](user:uid) ...". Same grammar as task.description.
  body       text NOT NULL,
  edited     tinyint(1) NOT NULL DEFAULT 0,
  ctime      int(11) NOT NULL DEFAULT 0,
  mtime      int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_task (task_id),
  KEY idx_author (author_uid),
  KEY idx_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Cascade delete of task_comment + task_comment_reaction rows is handled
-- explicitly in task_delete / task_comment_delete.
