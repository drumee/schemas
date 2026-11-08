-- Migration — existing hub / drumate databases
-- Creates `task_comment_read` (per-user read marks for task comments, used by
-- the subtask unread-comment badge) and stamps the feature epoch, so comments
-- written before this patch count as read for everyone.
-- Safe to run multiple times: the table is IF NOT EXISTS and the epoch is
-- INSERT IGNORE, so a re-run never moves it.
--
-- Apply to every common-class DB individually, e.g.:
--   bin/patch-from-file common/patches/create_task_comment_read.sql common

-- Skip instances that don't have the task table (tasks feature never
-- provisioned) — patch.js treats an error as fatal for the whole fleet run.
SET @tbl_exists = (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
);

SET @sql = IF(
  @tbl_exists = 0,
  'SELECT "no task table — skipped" AS info',
  'CREATE TABLE IF NOT EXISTS task_comment_read (
     task_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
     uid     varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
     read_ts int(11) NOT NULL DEFAULT 0,
     PRIMARY KEY (task_id, uid),
     KEY idx_uid (uid)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- The epoch: the baseline for any (task, uid) without a read mark of its own.
SET @sql = IF(
  @tbl_exists = 0,
  'SELECT "no task table — skipped" AS info',
  'INSERT IGNORE INTO task_comment_read (task_id, uid, read_ts) VALUES (''*'', ''*'', UNIX_TIMESTAMP())'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
