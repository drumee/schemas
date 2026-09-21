-- File: schemas/yellow_page/tables/feature_usage_day.sql
-- Purpose: one row per (user, feature, DAY) — the per-day counters behind the
--          Engagement pages' "Avg x/user" cards, which feature_usage alone
--          cannot answer.
--
-- WHY THIS EXISTS. feature_usage keeps one row per (user, feature): ctime is
-- the FIRST use and hits/volume are running totals feature_mark adds to. That
-- answers "who has ever used chat" and "how much in total", but never "how
-- much in March" — a running total cannot be cut at a date. Chat, task and
-- meeting have no event trail anywhere in yp to fall back on either: messages
-- live in `channel` (one table per WORKSPACE) and `p2p_channel` (one per
-- USER), tasks in a common/ table that exists once per hub, and yp.conference
-- rows are DELETED when the call ends. Uploads are the one exception, and are
-- counted from mfs_changelog instead.
--
-- IT STARTS EMPTY AND CANNOT BE BACKFILLED. The history it would need was
-- never recorded anywhere — that is the whole reason feature_usage is a table
-- of totals. So the earliest day here is the day this shipped, and
-- core_function_window returns MIN(day) as `day_since` precisely so the page
-- can say that rather than present a short count as a full one.
--
-- feature_usage is NOT replaced. It stays the complete lifetime record
-- (including everything from before this table), and the page reads it
-- whenever no range is selected.
CREATE TABLE IF NOT EXISTS `feature_usage_day` (
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Reference to yp.drumate.id',
  -- The SAME enum as feature_usage, deliberately: feature_mark validates
  -- against that list and writes both tables in one call, so a key that is
  -- legal in one and not the other could only ever be a silent drop.
  `feature` enum('upload','chat','task','meeting','file_thread','gdrive','upgrade_click','selfhosted_click') NOT NULL COMMENT 'Which feature this day''s counters belong to',
  `day` date NOT NULL COMMENT 'The day these counters cover, in server time',
  `hits` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'Uses on that day',
  `volume` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'Bytes on that day, where the feature carries a size',
  PRIMARY KEY (`uid`,`feature`,`day`),
  -- The read pattern: one feature, a range of days, summed across users.
  KEY `idx_feature_day` (`feature`,`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Per-day feature counters — the windowable twin of feature_usage'
