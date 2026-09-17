-- =========================================================
-- Add secure_share_access_event.creator_deleted_at -- the
-- share-open counterpart of creator_seen_at, added by
-- add_creator_seen_at_to_secure_share_access_event.sql. Read
-- that one first; this records only what differs.
--
-- creator_seen_at means READ and keeps meaning exactly that.
-- Since 2026-08-28 a read notification stays in the panel
-- (Lexis), so "seen" can no longer double as "gone" -- which
-- is what it did while the panel opened unread-only and a seen
-- row was simply filtered out. This column is the missing
-- second bit.
--
-- secure_share_open_feed is deliberately NOT modified. It
-- serves the whole share-open feed, and teaching it about a
-- column that may not exist yet would make it fail on any
-- instance missing this patch -- and the driver swallows SQL
-- errors and returns undefined rather than throwing, so the
-- failure would surface as silently missing notifications. The
-- filtering is done by the caller instead, via
-- activity_get_deleted_ids, where a missing column costs at
-- most a deleted row reappearing.
--
-- NOT BACKFILLED. creator_seen_at is a READ POINTER, not a
-- record of a per-row action: secure_share_mark_all_open_seen
-- stamps it on EVERY one of the creator's share-open events in
-- one statement, and service/private/activity.js mark_all_read
-- calls exactly that. Backfilling creator_deleted_at from it
-- would permanently delete every share-open notification
-- belonging to anyone who had ever pressed "Mark all as read".
-- The rows keep the default NULL and therefore stay visible as
-- read history, which is what the feature is for.
-- =========================================================

ALTER TABLE `secure_share_access_event`
  ADD COLUMN IF NOT EXISTS `creator_deleted_at` int(11) DEFAULT NULL
    COMMENT 'when the creator removed this open-notification with the trash button';
