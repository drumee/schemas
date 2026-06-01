-- ALTER TABLE migration — existing hub databases
-- Two changes, bundled (both touch the `task` schema):
--   1. Folder scoping: add `task.nid` (the folder node the task belongs to).
--      Existing rows keep nid = NULL; a NULL task is treated as a legacy /
--      workspace-level task and surfaces only at the workspace root view
--      (the client passes include_unscoped=1 there). No nid backfill — this
--      avoids having to resolve each hub's root node id in SQL, and existing
--      tasks remain visible exactly where they conceptually lived (the root).
--   2. Multi-assignee: create `task_assignee` and backfill it from the
--      legacy single `task.assignee_uid`. The old column is left in place
--      (non-destructive) but is no longer read or written by the SPs.
--
-- Safe to run multiple times. Apply to every hub DB individually, e.g.:
--   mariadb <hub_db_name> < alter_task_folder_scope_and_multi_assignee.sql

-- ---------------------------------------------------------------------------
-- task.nid
-- ---------------------------------------------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'nid'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `nid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NULL AFTER `assignee_uid`',
  'SELECT "task.nid column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- idx_nid
-- ---------------------------------------------------------------------------
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND INDEX_NAME   = 'idx_nid'
);

SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE `task` ADD KEY `idx_nid` (`nid`)',
  'SELECT "task.idx_nid already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task_assignee junction (multi-assignee)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `task_assignee` (
  `task_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uid`     VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime`   INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`task_id`, `uid`),
  KEY `idx_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- Backfill task_assignee from the legacy single assignee_uid.
-- INSERT IGNORE keeps this idempotent (re-runnable) — already-migrated rows
-- collide on the PK and are skipped.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `task_assignee` (`task_id`, `uid`, `ctime`)
SELECT t.id, t.assignee_uid, IFNULL(t.ctime, UNIX_TIMESTAMP())
  FROM `task` t
 WHERE t.assignee_uid IS NOT NULL
   AND t.assignee_uid <> '';

-- The single-assignee proc is replaced by task_set_assignees (multi). Drop the
-- orphan so deployed hub DBs don't keep a stale procedure around.
DROP PROCEDURE IF EXISTS `task_update_assignee`;
