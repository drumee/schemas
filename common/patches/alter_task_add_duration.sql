-- ALTER TABLE migration — existing hub / drumate databases
-- Adds `start_date` to `task` for the Duration (start -> end range) feature.
-- NULL start_date = single-date task; when set, the task spans
-- start_date .. due_date. Safe to run multiple times.
--
-- Apply to every common-class DB individually, e.g.:
--   bin/patch-from-file common/patches/alter_task_add_duration.sql common

-- ---------------------------------------------------------------------------
-- task.start_date
-- ---------------------------------------------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'start_date'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `start_date` DATE NULL AFTER `due_date`',
  'SELECT "task.start_date column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
