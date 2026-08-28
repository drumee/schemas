-- =========================================================
-- Add contact_activity.deleted_at -- the yp-side half of the
-- same split described in
-- drumate/patches/alter_mfs_dismissed_add_deleted.sql. Read
-- that header first; the argument is identical and this one
-- records only what differs.
--
-- Contact-side notifications (invite / accepted / refused,
-- plus task assignments, task @-mentions, watched-column
-- moves, meeting notices and storage alerts -- everything that
-- lives in this table) carry their read state in dismissed_at:
-- activity_get_feed_all computes
-- is_read = IF(c.dismissed_at IS NULL, 0, 1). That column
-- therefore already means "read" and keeps meaning exactly
-- that. deleted_at is the new, separate bit for "removed by
-- the trash button".
--
-- A TIMESTAMP, NOT A FLAG, unlike the drumate side. This table
-- already spells dismissal as a nullable timestamp, and
-- matching it keeps the two columns readable side by side and
-- records WHEN the user deleted the row -- useful when a user
-- reports a notification they did not expect to lose.
-- mfs_dismissed has no such precedent and its row already
-- carries mtime, so a flag is the smaller change there.
--
-- contact_activity_dismiss is NOT modified: no arity change,
-- no contract change, nothing for production to trip over.
-- Deletion gets a new procedure, contact_activity_delete.
--
-- BACKFILLED FROM dismissed_at FOR THE SAME REASON: every row
-- already dismissed was dismissed under the old, merged
-- meaning, so it stays hidden rather than reappearing as read
-- history on the first load after deployment.
--
-- Guarded on the column not existing so the ALTER and the
-- one-shot backfill run exactly once. An unguarded replay
-- would sweep every legitimately-read row into deleted_at and
-- silently empty panels.
--
-- This table lives in yp and is shared by every user, so the
-- ALTER is a single statement against one table -- 767 rows on
-- production at the time of writing, i.e. instant.
-- =========================================================

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'contact_activity'
    AND COLUMN_NAME  = 'deleted_at'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `contact_activity` ADD COLUMN `deleted_at` INT(11) UNSIGNED DEFAULT NULL COMMENT ''When the recipient removed this row with the trash button; never shown again'' AFTER `dismissed_at`, ADD INDEX `idx_deleted_at` (`deleted_at`)',
  'SELECT "contact_activity.deleted_at column already exists -- skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @backfill = IF(
  @col_exists = 0,
  'UPDATE `contact_activity` SET `deleted_at` = `dismissed_at` WHERE `dismissed_at` IS NOT NULL',
  'SELECT "contact_activity.deleted_at backfill already done -- skipped" AS info'
);

PREPARE stmt FROM @backfill;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
