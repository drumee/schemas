-- Support activity_get_feed_all's accessible-hub join and newest-first page.
-- Idempotent and independently reversible with:
--   ALTER TABLE mfs_changelog DROP INDEX IF EXISTS idx_hub_timestamp;

ALTER TABLE mfs_changelog
  ADD INDEX IF NOT EXISTS idx_hub_timestamp (`hub_id`, `timestamp`, `id`),
  ALGORITHM=INPLACE, LOCK=NONE;
