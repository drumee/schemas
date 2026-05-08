-- Apply: mariadb yp < alter_contact_activity_add_dismissed_at.sql
-- Adds `dismissed_at` to contact_activity so users can hide rows
-- (mark-all-read, individual dismiss) without losing the underlying event.
-- Idempotent — guarded by information_schema check.

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'contact_activity'
    AND COLUMN_NAME  = 'dismissed_at'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `contact_activity` ADD COLUMN `dismissed_at` INT(11) UNSIGNED DEFAULT NULL AFTER `data`, ADD INDEX `idx_dismissed_at` (`dismissed_at`)',
  'SELECT "dismissed_at column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
