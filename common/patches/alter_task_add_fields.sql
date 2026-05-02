-- ALTER TABLE migration — existing hub databases
-- Adds description, priority, assignee_uid to `task` and creates the
-- `label` master + `task_label` junction tables.
-- Safe to run multiple times.
--
-- Apply this to every hub DB individually, e.g.:
--   mariadb <hub_db_name> < alter_task_add_fields.sql

-- ---------------------------------------------------------------------------
-- task.description
-- ---------------------------------------------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'description'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `description` TEXT NULL AFTER `title`',
  'SELECT "task.description column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task.priority
-- ---------------------------------------------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'priority'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `priority` ENUM(''low'',''medium'',''high'',''urgent'') NOT NULL DEFAULT ''medium'' AFTER `status`',
  'SELECT "task.priority column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- idx_priority
-- ---------------------------------------------------------------------------
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND INDEX_NAME   = 'idx_priority'
);

SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE `task` ADD KEY `idx_priority` (`priority`)',
  'SELECT "task.idx_priority already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task.assignee_uid
-- ---------------------------------------------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'assignee_uid'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `assignee_uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NULL AFTER `created_by`',
  'SELECT "task.assignee_uid column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- idx_assignee_uid
-- ---------------------------------------------------------------------------
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND INDEX_NAME   = 'idx_assignee_uid'
);

SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE `task` ADD KEY `idx_assignee_uid` (`assignee_uid`)',
  'SELECT "task.idx_assignee_uid already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- label table (per-hub label master)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `label` (
  `id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `color` VARCHAR(9) NOT NULL DEFAULT '#AEAEB2',
  `created_by` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime` INT(11) NOT NULL DEFAULT 0,
  `mtime` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- task_label junction
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `task_label` (
  `task_id`  VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `label_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime`    INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`task_id`, `label_id`),
  KEY `idx_label_id` (`label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Cascade delete handled explicitly in task_delete and label_delete SPs.
