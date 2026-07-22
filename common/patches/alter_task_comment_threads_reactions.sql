-- ALTER TABLE migration — existing hub databases
-- Adds threaded replies (task_comment.parent_id) and reactions
-- (task_comment_reaction) to the task comment feature.
--
-- Safe to run multiple times. Apply to every hub DB individually, e.g.:
--   mariadb <hub_db_name> < alter_task_comment_threads_reactions.sql
--
-- The task_comment_* procedures + task_delete cascade are deployed from
-- common/procedures/task/ (procedures are replaced wholesale on deploy).

-- ---------------------------------------------------------------------------
-- task_comment.parent_id
-- ---------------------------------------------------------------------------
-- Guarded on the TABLE as well as the column: information_schema.COLUMNS
-- returns 0 both when the column is missing AND when the table itself is
-- missing, so the original guard took the "apply" branch on a database with no
-- `task_comment` table and died with ER_NO_SUCH_TABLE (1146) — which patch.js treats
-- as fatal, aborting the whole fleet run at that database.
SET @has_tbl := (
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task_comment'
);

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task_comment'
    AND COLUMN_NAME  = 'parent_id'
);

SET @sql = IF(
  @has_tbl = 1 AND @col_exists = 0,
  'ALTER TABLE `task_comment` ADD COLUMN `parent_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NULL AFTER `author_uid`, ADD KEY `idx_parent` (`parent_id`)',
  'SELECT "task_comment.parent_id already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task_comment_reaction
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `task_comment_reaction` (
  `comment_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uid`        varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `emoji`      varchar(32) NOT NULL,
  `ctime`      int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`comment_id`, `uid`, `emoji`),
  KEY `idx_comment` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
