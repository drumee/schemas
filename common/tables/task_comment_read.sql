-- Per-user read mark for a task's comments: one high-water timestamp per
-- (task, user). A comment is unread for `uid` when someone else wrote it with
-- ctime > read_ts. Stamped by task_comment_mark_read when the user opens the
-- task's detail; read by task_comment_unread_counts.
--
-- The row ('*', '*', <ts>) is the feature epoch, stamped once by
-- patches/create_task_comment_read.sql: a (task, uid) pair with no row of its
-- own uses it as its baseline, so comments that predate the rollout count as
-- read. A fresh instance has no epoch row and no history, so its baseline is 0.
CREATE TABLE IF NOT EXISTS task_comment_read (
  task_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  uid     varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  read_ts int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (task_id, uid),
  KEY idx_uid (uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Rows of a deleted task (and its subtasks) are removed in task_delete.
