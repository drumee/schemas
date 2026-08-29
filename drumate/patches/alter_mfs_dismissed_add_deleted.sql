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
-- EXISTING ROWS ARE **NOT** BACKFILLED -- they all default to
-- 0, i.e. "read but not deleted", and therefore stay visible
-- as read history. An earlier draft of this patch backfilled
-- them to 1 to avoid surprising users with old notifications
-- reappearing. That was WRONG and was reverted on 2026-08-29:
-- every row here predates the split and is an unknowable mix
-- of "I clicked to read it" and "I trashed it", and the
-- overwhelming majority are the former, because under the old
-- code an ordinary body click wrote this table. Backfilling to
-- 1 therefore PERMANENTLY deleted read history -- the exact
-- history this feature exists to preserve.
--
-- The asymmetry decides it: a row reappearing is a minor
-- annoyance the user can trash again, while a row deleted
-- because it had merely been read is unrecoverable. And the
-- "flood" this was guarding against is not one: these rows are
-- READ rows -- untinted, in chronological order, behind a
-- 45-row page.
-- =========================================================

ALTER TABLE `mfs_dismissed`
  ADD COLUMN IF NOT EXISTS `deleted` TINYINT(1) NOT NULL DEFAULT 0
    COMMENT '1 = removed by the trash button, never shown again'
    AFTER `mtime`,
  ADD INDEX IF NOT EXISTS `idx_deleted` (`deleted`);
