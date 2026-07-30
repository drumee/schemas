-- Apply: mariadb yp < alter_meeting_schedule_message.sql
-- Idempotent — guarded by information_schema check.
--
-- The meeting reminder card shows the agenda under the title, so the worker
-- needs it alongside `title`. It lives in the schedule node's metadata
-- (content.message) in a per-hub database, which the worker cannot reach —
-- hence a copy in the global index, written through by room.book/update the
-- same way the title is.

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'meeting_schedule'
    AND COLUMN_NAME  = 'message'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `meeting_schedule` ADD COLUMN `message` TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL AFTER `title`',
  'SELECT "message column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
