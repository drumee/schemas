CREATE TABLE IF NOT EXISTS task_comment_file (
  comment_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  file_nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  linked_by varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  ctime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (comment_id, file_nid),
  KEY idx_file_nid (file_nid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Files attached to a single comment, as opposed to task_file which attaches
-- them to the task as a whole. The file itself is an ordinary media node in the
-- folder body; this table only records that the comment points at it, so
-- unlinking never touches the file.
-- Cascade delete of task_comment_file rows is handled explicitly in
-- task_comment_delete (root + its replies) and task_delete (whole task).
