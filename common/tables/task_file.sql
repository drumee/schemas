CREATE TABLE IF NOT EXISTS task_file (
  task_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  file_nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  linked_by varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  ctime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (task_id, file_nid),
  KEY idx_file_nid (file_nid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Cascade delete of task_file rows is handled explicitly in the task_delete SP.