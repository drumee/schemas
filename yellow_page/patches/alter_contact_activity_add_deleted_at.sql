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
-- NOT BACKFILLED, and here the reason is even sharper than on
-- the drumate side. "Mark all as read" does not touch a
-- watermark for this table -- service/private/activity.js
-- mark_all_read ENUMERATES the caller's unread contact events
-- and calls contact_activity_dismiss on each one. So a single
-- press of that button stamps dismissed_at on dozens of rows.
-- An earlier draft backfilled deleted_at from dismissed_at;
-- that would have permanently deleted every contact
-- notification belonging to anyone who had ever pressed "Mark
-- all as read". Reverted on 2026-08-29 along with the 233 rows
-- it had already marked on stage.
--
-- This table lives in yp and is shared by every user, so the
-- ALTER is a single statement against one table -- 582 rows on
-- stage, 767 on production at the time of writing.
-- =========================================================

ALTER TABLE `contact_activity`
  ADD COLUMN IF NOT EXISTS `deleted_at` INT(11) UNSIGNED DEFAULT NULL
    COMMENT 'When the recipient removed this row with the trash button; never shown again'
    AFTER `dismissed_at`,
  ADD INDEX IF NOT EXISTS `idx_deleted_at` (`deleted_at`);
