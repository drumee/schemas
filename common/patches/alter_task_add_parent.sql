-- ALTER TABLE migration — existing hub / drumate databases
-- Adds `parent_task_id` to `task` for the Subtask (parent/child) feature.
-- NULL = a normal top-level task; set = a subtask of that task id.
-- Nesting is limited to ONE level: a task whose parent_task_id is set can never
-- itself be a parent. That rule is enforced in the service layer (task.create),
-- not here — SQL cannot express it declaratively without a trigger.
-- Safe to run multiple times.
--
-- Apply to every common-class DB individually, e.g.:
--   bin/patch-from-file common/patches/alter_task_add_parent.sql common

-- ---------------------------------------------------------------------------
-- task.parent_task_id
-- ---------------------------------------------------------------------------
-- Skip instances that don't have the task table yet (e.g. installs where the
-- tasks feature was never provisioned) instead of erroring on ALTER. 156 of the
-- stage databases have no task tables at all, and patch.js treats
-- ER_NO_SUCH_TABLE (1146) as fatal for the whole fleet run.
SET @tbl_exists = (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
);

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'parent_task_id'
);

-- CHARACTER SET ascii is NOT optional: it must match task.id / task.nid, which
-- are ascii_general_ci. A utf8mb4 column here makes every self-join and every
-- DECLARE against it raise ER_CANT_AGGREGATE_2COLLATIONS (1267) — the same trap
-- documented in task_update_status.
SET @sql = IF(
  @tbl_exists = 0,
  'SELECT "no task table — skipped" AS info',
  IF(
    @col_exists = 0,
    'ALTER TABLE `task` ADD COLUMN `parent_task_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL AFTER `nid`',
    'SELECT "task.parent_task_id column already exists — skipped" AS info'
  )
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task.idx_parent_task_id
-- ---------------------------------------------------------------------------
-- Every task row now carries two correlated subqueries counting its children,
-- and task_list runs them for the whole folder — without this index that is a
-- full table scan per row.
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND INDEX_NAME   = 'idx_parent_task_id'
);

SET @sql = IF(
  @tbl_exists = 0,
  'SELECT "no task table — skipped" AS info',
  IF(
    @idx_exists = 0,
    'ALTER TABLE `task` ADD KEY `idx_parent_task_id` (`parent_task_id`)',
    'SELECT "task.idx_parent_task_id already exists — skipped" AS info'
  )
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
