-- Apply: mariadb yp < alter_socket_add_mtime.sql
-- Idempotent — guarded by information_schema check.

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'socket'
    AND COLUMN_NAME  = 'mtime'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `socket` ADD COLUMN `mtime` INT(11) NOT NULL DEFAULT 0 AFTER `ctime`',
  'SELECT "mtime column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
