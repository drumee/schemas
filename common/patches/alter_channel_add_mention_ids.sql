-- ALTER TABLE migration — existing hub databases
-- Run once per hub DB on stage and production
-- Safe to run multiple times (IF NOT EXISTS check)
--
-- Apply this to every hub DB individually, e.g.:
--   mariadb <hub_db_name> < alter_channel_add_mention_ids.sql

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'channel'
    AND COLUMN_NAME  = 'mention_ids'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `channel` ADD COLUMN `mention_ids` JSON NULL AFTER `is_forward`',
  'SELECT "mention_ids column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;