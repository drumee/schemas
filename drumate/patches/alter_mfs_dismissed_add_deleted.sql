-- =========================================================
-- Add mfs_dismissed.deleted -- split "I read this" from
-- "I deleted this".
--
-- Lexis, 2026-08-28: reading a notification must no longer
-- remove it from the panel. The row stays and renders without
-- the unread card tint; only the trash button removes it, and
-- that removal is permanent.
--
-- Today those two actions are INDISTINGUISHABLE. A row in this
-- table is written by BOTH the trash button and an ordinary
-- body click (panel/activity/widget/item/index.js fires
-- dismiss-activity from twelve click sites), and
-- activity_get_feed_all reads the row's mere existence as
-- is_read = 1. So the table already means "read"; what it
-- cannot express is "and gone for good". This column adds
-- exactly that one bit, and nothing else.
--
-- WHY NOT A NEW PARAMETER ON mfs_dismiss_activity: that would
-- change the procedure's arity, and production code calls it
-- with the current one. MariaDB stored procedures have no
-- default parameters, so an arity change breaks every existing
-- caller the moment it is applied -- this is precisely what
-- took task_create/task_update down on 2026-08-27. Instead
-- mfs_dismiss_activity is left untouched and keeps meaning
-- "mark read" (its INSERT omits this column, so the DEFAULT 0
-- applies), and deletion gets its own new procedure,
-- mfs_delete_activity. A brand-new name has no existing
-- callers and therefore cannot break anything.
--
-- EXISTING ROWS ARE BACKFILLED TO 1, NOT 0. Every row already
-- in this table was written before the split existed, so it is
-- an unknowable mix of "I clicked to read it" and "I trashed
-- it" -- there is no field that separates them retroactively.
-- Backfilling to 0 would make all of that history reappear in
-- the panel as read rows the next time the user opens it:
-- potentially hundreds of notifications a user believed they
-- had cleared months ago, arriving as a surprise on the first
-- load after deployment. Backfilling to 1 keeps every existing
-- row exactly as hidden as it is today, so the new behaviour
-- applies from deployment forward and no user's panel changes
-- retroactively. The conservative direction is the one that
-- alters nothing a user has already seen.
--
-- Guarded on the column not existing, so the ALTER and the
-- one-shot backfill run together exactly once. This matters:
-- an unguarded replay would re-run the UPDATE and mark every
-- legitimately-read row as deleted, silently emptying panels.
-- Same guard style as alter_contact_add_dismissed_at.sql.
-- =========================================================

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'mfs_dismissed'
    AND COLUMN_NAME  = 'deleted'
);

SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `mfs_dismissed` ADD COLUMN `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = removed by the trash button, never shown again'' AFTER `mtime`, ADD INDEX `idx_deleted` (`deleted`)',
  'SELECT "mfs_dismissed.deleted column already exists -- skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @backfill = IF(
  @col_exists = 0,
  'UPDATE `mfs_dismissed` SET `deleted` = 1',
  'SELECT "mfs_dismissed.deleted backfill already done -- skipped" AS info'
);

PREPARE stmt FROM @backfill;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
