-- File: schemas/yellow_page/tables/funnel_milestone.sql
-- Purpose: one row per (user, activation milestone), stamped the FIRST time
--          that user reached it. Feeds the analytics dashboard's Funnel page
--          (Activation > Funnel).
--
-- WHY A TABLE AND NOT A DERIVED QUERY. Three of the four milestones were
-- reachable from data already on disk, and the fourth was not:
--
--   folder / upload   MIN(timestamp) over yp.mfs_changelog. Derivable, but it
--                     is a full scan plus a JSON_VALUE per row on every page
--                     load, and the table is the busiest write path we have.
--   onboarded         NOT derivable. drumate.profile.$.onboarded is a BOOLEAN.
--                     Nothing anywhere records WHEN the wizard was finished,
--                     so a derived funnel could report that a user onboarded
--                     but never when -- no cohorting, no time-to-activate, no
--                     way to tell last week's conversion from last year's.
--   activated         both of the above, so it inherits their problems.
--
-- One undated milestone is enough to make the whole page unanswerable, which
-- is why this exists rather than a view.
--
-- PRIMARY KEY (uid, milestone) IS THE "FIRST TIME ONLY" RULE. Every writer is
-- INSERT IGNORE, so the second folder a user creates is a no-op in the storage
-- engine and no caller can get the semantics wrong by forgetting a guard. This
-- also makes the backfill re-runnable: running it twice produces the same
-- table.
--
-- NO FOREIGN KEY, deliberately, following signup_track: the row outlives the
-- account. Deleting a user must not retroactively shrink last quarter's
-- activation rate.
--
-- uid is utf8mb4_general_ci because yp.drumate.id is (verified live, not
-- assumed -- see the note in mfs_changelog.sql about the same column being
-- declared one way in the repo and another on disk). Every read of this table
-- joins drumate; a collation that merely *coerces* still costs a per-row
-- conversion and cannot seek the index.
--
-- WHAT IS NOT HERE: signup. It needs no row -- yp.entity.ctime already is the
-- signup timestamp, and joining entity to drumate is already the dashboard's
-- definition of a real user. Storing it again would be a second copy of a
-- fact that can only disagree with the first.

CREATE TABLE IF NOT EXISTS `funnel_milestone` (
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Reference to yp.drumate.id',
  `milestone` enum('onboarded','folder','upload','activated') NOT NULL COMMENT 'Which activation stage this row records',
  `ctime` int(11) unsigned NOT NULL COMMENT 'When the user FIRST reached this milestone',
  `approx` tinyint(1) unsigned NOT NULL DEFAULT 0 COMMENT '1 = ctime is a backfilled stand-in, not a measured moment. Only ever set on backfilled `onboarded` rows, whose real completion time was never recorded',
  PRIMARY KEY (`uid`,`milestone`),
  KEY `idx_milestone_ctime` (`milestone`,`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Activation funnel — one row per user per milestone, first occurrence only'
