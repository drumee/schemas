-- File: schemas/yellow_page/tables/feature_usage.sql
-- Purpose: one row per (user, core feature), stamped the FIRST time that user
--          used it and carrying running totals since. Feeds the analytics
--          dashboard's Engagement > Core function page.
--
-- WHY A TABLE AND NOT A DERIVED QUERY. Only one of the four features leaves a
-- trace in yp at all:
--
--   upload    yp.mfs_changelog event='media.new' — derivable, but it is a full
--             scan plus a JSON_VALUE per row on every page load, over the
--             busiest write path we have.
--   chat      NOT derivable. Messages live in `channel` (one table per
--             WORKSPACE) and `p2p_channel` (one per USER). Counting them means
--             enumerating every instance on the server.
--   task      NOT derivable, same reason — `task` is a common/ table, so it
--             exists once per hub and once per drumate.
--   meeting   NOT derivable. yp.conference is a per-SOCKET participant table
--             whose rows are DELETED on leave; after the call there is nothing
--             left to count.
--
-- THE KEY IS THE "FIRST TIME ONLY" RULE, exactly as in funnel_milestone.
-- `ctime` is written by the INSERT and never appears in an ON DUPLICATE KEY
-- UPDATE clause, so it always means first use no matter how many events land.
--
-- WHY COUNTERS SHARE THE ROW rather than living in a second table. The page
-- needs both "how many users touched chat" (the row's existence) and "how many
-- messages did they send" (hits). Two tables would be two writes per event and
-- two answers to "has this user used chat" that can disagree after a purge.
-- One row, one upsert, one truth.
--
-- `volume` IS BYTES AND ONLY UPLOAD USES IT. It is the cumulative size of every
-- file the user has ever uploaded — NOT their current disk footprint. Deleting
-- a file does not decrease it. The dashboard labels it accordingly; anyone
-- wanting live storage wants yp.disk_usage, which is per-HUB and has no user
-- attribution or time dimension.
--
-- NO FOREIGN KEY, deliberately, following funnel_milestone and signup_track:
-- the row outlives the account. Deleting a user must not retroactively shrink
-- last quarter's adoption.
--
-- uid is utf8mb4_general_ci because yp.drumate.id is (verified live, not
-- assumed). Every read of this table joins drumate; a collation that merely
-- coerces still costs a per-row conversion and cannot seek the index.

CREATE TABLE IF NOT EXISTS `feature_usage` (
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.drumate.id',
  `feature` enum('upload','chat','task','meeting') NOT NULL
    COMMENT 'Which core feature this row records',
  `ctime` int(11) unsigned NOT NULL
    COMMENT 'When the user FIRST used this feature. Never updated.',
  `hits` int(11) unsigned NOT NULL DEFAULT 0
    COMMENT 'Uses since: files uploaded, messages sent, tasks created, meetings joined',
  `volume` bigint(20) unsigned NOT NULL DEFAULT 0
    COMMENT 'Cumulative bytes uploaded. Upload rows only; 0 elsewhere.',
  PRIMARY KEY (`uid`,`feature`),
  KEY `idx_feature_ctime` (`feature`,`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Core feature adoption — one row per user per feature, first use + running totals'
