-- Persistent per-creator "seen" marker for share-open notifications. NULL until
-- the creator has seen/dismissed the open event in the activity panel. Compared
-- against last_seen_at so a recipient re-opening (newer last_seen_at) resurfaces
-- the notification as unread, matching the read-pointer model of other feeds.
-- Backward-compatible (nullable add); enables share-opens to behave like normal
-- feed events (Unread ON hides seen, Unread OFF shows all) instead of a pinned
-- 7-day rolling alert.
ALTER TABLE `secure_share_access_event`
  ADD COLUMN IF NOT EXISTS `creator_seen_at` int(11) DEFAULT NULL;
