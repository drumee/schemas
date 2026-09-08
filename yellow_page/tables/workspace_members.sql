-- File: schemas/yellow_page/tables/workspace_members.sql
-- Purpose: one row per collaborative workspace carrying its current member
--          count. Feeds "Avg team size" on the analytics dashboard's
--          Engagement > Viral loop page.
--
-- WHY A ROLLUP AND NOT A QUERY. Workspace membership is not stored in yp at
-- all. It lives in each hub's OWN database, in `permission` rows with
-- resource_id = '*' -- which is what hub_get_members_by_type reads and the only
-- place the truth exists. yp.membership looks like the table for this and is
-- not: it holds zero rows on every install checked (2026-08-26), and nothing
-- writes it.
--
-- Counting members system-wide therefore means visiting every hub database.
-- The read path must never do that: analytics.viral_loop runs on every page
-- load and would get slower with every workspace created, which is the entire
-- reason this table exists. The same argument, and the same conclusion, as
-- yp.feature_usage -- see the header of patches/feature_usage_backfill.sql for
-- why a one-time crawl is acceptable on the write side and nowhere else.
--
-- WHAT COUNTS AS A WORKSPACE is not this table's decision to make. It reuses
-- the definition analytics-server already settled on in
-- patches/backfill_workspace_track.sql: yp.entity.type = 'hub' AND
-- yp.entity.area IN ('private','share'), minus the two hubs signup pre-creates
-- on every desk ('Internal Workspace', 'External Workspace'). Excluded by that
-- rule and worth naming, because they dominate the row count on a real
-- install: area 'pool' (pre-allocated empty shells -- 210 of this box's 216
-- hubs), 'dmz' (auto-hubs behind meetings and share links), and 'public'
-- (system hubs: backoffice, stripe, reward, Onboarding). A denominator that
-- swept those in would report an avg team size near 1.0 for every install, and
-- it would be near 1.0 whether or not anybody collaborates -- a number that
-- cannot move is not a measurement.
--
-- `members` COUNTS PEOPLE WITH A LIVE GRANT, owner included. The owner holds a
-- permission row like anybody else, so no special case is needed on the write
-- side, and "members / account" reads as team size rather than as invitees.
--
-- MAINTAINED BY THE THREE PATHS THAT MUTATE MEMBERSHIP, all in server-team
-- service/private/hub.js and service/signup.js: _grantMembership (+1),
-- delete_contributor (-n), and signup's _resolve_pending_invitation (+1). They
-- call workspace_members_set with the count they just produced rather than a
-- delta, so a missed event self-corrects on the next mutation instead of
-- drifting permanently.
--
-- STALE IS THE EXPECTED FAILURE MODE, not wrong. If a writer is missed the row
-- lags until the next mutation on that workspace or the next backfill run;
-- re-running patches/workspace_members_backfill.sql reconciles every row.
--
-- NO FOREIGN KEY, following every other tracking table here: the row outlives
-- the hub, so deleting a workspace does not retroactively change last
-- quarter's average.

CREATE TABLE IF NOT EXISTS `workspace_members` (
  `hub_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.hub.id',
  `owner_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
    COMMENT 'Reference to yp.drumate.id -- yp.hub.owner_id at the time of writing',
  `area` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
    COMMENT "yp.entity.area -- 'private' (internal) or 'share' (external)",
  `members` int(11) unsigned NOT NULL DEFAULT 0
    COMMENT "Live permission rows with resource_id='*' in the hub's own database, owner included",
  `ctime` int(11) unsigned NOT NULL
    COMMENT 'When this workspace was first counted',
  `mtime` int(11) unsigned NOT NULL
    COMMENT 'When the count was last refreshed',
  PRIMARY KEY (`hub_id`),
  KEY `idx_area` (`area`),
  KEY `idx_owner` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Viral loop -- current member count per collaborative workspace'
