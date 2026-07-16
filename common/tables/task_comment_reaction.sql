CREATE TABLE IF NOT EXISTS task_comment_reaction (
  comment_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  uid        varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- utf8mb4_bin so distinct emojis compare byte-exact: the PK is
  -- (comment_id, uid, emoji), and under utf8mb4_general_ci many emojis collate
  -- as equal (esp. older servers), which collapses all of a user's reactions
  -- into one row and makes the toggle proc delete the wrong one.
  emoji      varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  ctime      int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (comment_id, uid, emoji),
  KEY idx_comment (comment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
