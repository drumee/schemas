-- Apply: mariadb yp < alter_meeting_schedule_early_fired.sql
-- Idempotent — guarded by information_schema check.
--
-- Adds the second reminder flag. A meeting now produces TWO pushes: a heads-up
-- a fixed lead time before the start (`early_fired`) and the "starting now"
-- announcement (`fired`). They need separate flags or the heads-up would
-- suppress the real one. Both reset together when a meeting is moved or a
-- recurring series rolls to its next occurrence.

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'meeting_schedule'
    AND COLUMN_NAME  = 'early_fired'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `meeting_schedule` ADD COLUMN `early_fired` TINYINT(1) NOT NULL DEFAULT 0 AFTER `fired`',
  'SELECT "early_fired column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Index the heads-up scan the same way `due` indexes the start scan.
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'meeting_schedule'
    AND INDEX_NAME   = 'upcoming'
);

SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE `meeting_schedule` ADD KEY `upcoming` (`early_fired`,`stime`)',
  'SELECT "upcoming index already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
