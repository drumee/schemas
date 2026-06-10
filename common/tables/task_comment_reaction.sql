CREATE TABLE IF NOT EXISTS task_comment_reaction (
  comment_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  uid        varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  emoji      varchar(32) NOT NULL,
  ctime      int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (comment_id, uid, emoji),
  KEY idx_comment (comment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
