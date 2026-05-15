-- Apply: per drumate DB
--   for db in $(mariadb -BN -e "SELECT db_name FROM yp.entity WHERE type='drumate'"); do
--     mariadb "$db" < alter_contact_add_dismissed_at.sql
--   done
-- Adds `dismissed_at` to drumate.contact so notification_center can hide
-- contact-invite rollups the user has acknowledged.
-- Idempotent — guarded by information_schema check.

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'contact'
    AND COLUMN_NAME  = 'dismissed_at'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `contact` ADD COLUMN `dismissed_at` INT(11) UNSIGNED DEFAULT NULL AFTER `mtime`, ADD INDEX `idx_dismissed_at` (`dismissed_at`)',
  'SELECT "contact.dismissed_at column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
