-- ALTER TABLE migration — existing hub databases
-- Project Health view support:
--   1. task.completed_at — unix ts the task last entered 'complete' status.
--   2. task_activity      — per-folder activity feed (create/update/status/…).
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS, MariaDB 10.3+).
--
-- Apply to every hub DB individually, e.g.:
--   mariadb <hub_db_name> < alter_task_health_metrics.sql

-- ---------------------------------------------------------------------------
-- task.completed_at
--
-- Guarded on the table: not every common-class database has a `task` table,
-- and an unguarded statement there dies with ER_NO_SUCH_TABLE (1146), which
-- patch.js treats as fatal — aborting the whole fleet run at that database.
-- The CREATE TABLE below needs no guard (IF NOT EXISTS).
-- ---------------------------------------------------------------------------
SET @has_task := (
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task'
);

SET @sql := IF(
  @has_task = 1,
  'ALTER TABLE `task` ADD COLUMN IF NOT EXISTS `completed_at` INT(11) NOT NULL DEFAULT 0 AFTER `mtime`',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- Backfill: tasks already in 'complete' get their mtime as a best-effort
-- completion time (the real moment is unknown for pre-migration rows).
SET @sql := IF(
  @has_task = 1,
  'UPDATE `task` SET `completed_at` = `mtime` WHERE `status` = ''complete'' AND `completed_at` = 0',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- task_activity — folder-scoped activity feed
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `task_activity` (
  `sys_id`   INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`  VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- Denormalized folder scope copied from the task at log time, so the feed
  -- can be queried per-folder without joining task (and survives task delete).
  `nid`      VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `actor_uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `action`   ENUM('create','update','status','assignee','link_file','comment','complete') NOT NULL,
  -- Free-form JSON context (e.g. {"title":"…","status":"complete","count":3}).
  `meta`     TEXT DEFAULT NULL,
  `ctime`    INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  KEY `idx_nid_ctime` (`nid`, `ctime`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
