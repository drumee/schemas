CREATE TABLE IF NOT EXISTS task_assignee (
  task_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  ctime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (task_id, uid),
  KEY idx_uid (uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Cascade delete handled explicitly in task_delete.
