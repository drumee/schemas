-- ALTER TABLE migration — existing hub databases
-- Custom Kanban columns support:
--   1. task.status  enum → varchar(32) so tasks can live in user-created
--      columns (a custom column's task_column.id is its status key).
--   2. task_column  — user-created columns (name + palette theme + position),
--      folder-scoped like tasks. Built-in columns stay implicit client-side.
-- Safe to run multiple times (MODIFY is idempotent; CREATE IF NOT EXISTS).
--
-- Apply to every hub DB individually, e.g.:
--   mariadb <hub_db_name> < alter_task_custom_columns.sql

-- ---------------------------------------------------------------------------
-- task.status: enum → varchar
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
  'ALTER TABLE `task` MODIFY `status` VARCHAR(32) NOT NULL DEFAULT ''todo''',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- task_column — user-created Kanban columns
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `task_column` (
  `id`       VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `nid`      VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `name`     VARCHAR(100) NOT NULL,
  `theme`    VARCHAR(20) NOT NULL DEFAULT 'default',
  `position` INT(11) NOT NULL DEFAULT 0,
  `ctime`    INT(11) NOT NULL DEFAULT 0,
  `mtime`    INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_nid` (`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
