-- File: schemas/patches/feature_usage_backfill.sql
-- Purpose: seed yp.feature_usage with the history that IS recoverable, so the
--          Core function page does not open reading zero for a two-year-old
--          install.
--
-- RE-RUNNABLE. Both statements are INSERT ... ON DUPLICATE KEY UPDATE with
-- absolute (not incremental) values, so running this twice produces the same
-- table. That is the opposite of feature_mark's contract, deliberately: this
-- replays a complete history and therefore KNOWS the total, whereas a live
-- event only knows its own delta.
--
-- THE REAL HAZARD IS UNDER-COUNTING, NOT DOUBLE-COUNTING. Because the upsert
-- is absolute (hits = VALUES(hits) replaces rather than adds), running this
-- after the services deploy does NOT double anything -- the replay total
-- simply overwrites whatever feature_mark had already accrued, and feature_mark
-- keeps accruing from there. The actual danger is a PRUNED SOURCE: if
-- mfs_changelog or services_log has been trimmed (retention job, manual
-- cleanup) by the time this runs, a late replay UNDER-counts, silently
-- lowering totals that were previously correct. Run this as early as
-- practical, before any source-table pruning, not to avoid double-counting.
--
-- ONLY TWO OF THE FOUR FEATURES ARE HERE. Chat and task leave no trace in yp
-- (per-workspace and per-user tables), so there is nothing to replay. They
-- start at zero on deploy day and the page says so.
--
-- =========================================================================
-- NEVER ADD THIS FILE TO patches/manifest.txt.
--
-- The manifest is applied wholesale on every patch run. Because this file's
-- upserts write ABSOLUTE totals (hits = VALUES(hits), not an increment), a
-- later unrelated manifest run that happens to include this file would reset
-- every live counter back to the totals captured at replay time -- silently
-- discarding every hit and every byte of volume collected since. Apply it
-- exactly once, by hand, with bin/patch-from-file, and keep it out of the
-- manifest permanently. (Contrast with funnel_backfill.sql, which IS in the
-- manifest -- its INSERT IGNORE against a PRIMARY KEY is safe to replay
-- wholesale because it never overwrites an existing row. This file's
-- ON DUPLICATE KEY UPDATE does the opposite, so the same treatment is unsafe
-- here.)
-- =========================================================================

-- ---------------------------------------------------------------
-- upload -- from mfs_changelog. One media.new row per file, with
-- src.filesize. Chat attachments are already absent: changelog_write
-- returns early for /__chat__/ paths, which is the same exclusion
-- media.js applies before calling feature_mark, so the backfill and
-- the live writer count the same population.
--
-- mimetype is the discriminator, not `event`: media.make_dir and
-- media.upload BOTH write event='media.new' (service/media.js), so
-- the event alone cannot tell a folder from a file, and without this
-- predicate a folder-only user would count as an "uploader". This
-- must match funnel_backfill.sql's upload statement exactly -- both
-- backfills need to select the same population, or Core function and
-- Funnel report contradictory things for the same user.
-- ---------------------------------------------------------------
INSERT INTO feature_usage (uid, feature, ctime, hits, volume)
SELECT
  c.uid,
  'upload',
  MIN(c.timestamp),
  COUNT(*),
  IFNULL(SUM(CAST(JSON_VALUE(c.src, '$.filesize') AS UNSIGNED)), 0)
FROM mfs_changelog c
INNER JOIN drumate d ON d.id = c.uid
WHERE c.event = 'media.new'
  AND IFNULL(JSON_VALUE(c.src, '$.mimetype'), '') <> 'folder'
  AND c.uid IS NOT NULL AND c.uid <> ''
GROUP BY c.uid
ON DUPLICATE KEY UPDATE
  ctime  = LEAST(feature_usage.ctime, VALUES(ctime)),
  hits   = VALUES(hits),
  volume = VALUES(volume);

-- ---------------------------------------------------------------
-- meeting -- from services_log, which carries a row per
-- conference.join because acl/conference.json sets "log": true.
--
-- DEDUPED PER (uid, room_id): join is per SOCKET, so one meeting
-- attended with a reload in the middle is two rows. Counting rows
-- would report twice the meetings anyone actually attended. The
-- inner GROUP BY s.uid, room_id is the whole point of this statement.
--
-- A NULL room_id means a row written before room_id was carried in
-- args; those collapse into a single 'unknown' meeting per user
-- rather than being dropped, which under-counts by less than
-- discarding them does.
--
-- EXCLUDES THE GUEST AND NOBODY ACCOUNTS. yp.drumate has a real row
-- for the shared DMZ guest account (id = sys_conf 'guest_id') and for
-- 'nobody_id'; every anonymous meeting join is logged under one of
-- these, so without the exclusion this statement would create one
-- shared feature_usage row accumulating every guest's joins across
-- every meeting, unbounded. get_sysconf() is compared against s.uid
-- directly -- verified live: get_sysconf('guest_id') =
-- '360deefd360def00' (drumate row guest@local.drumee) and
-- get_sysconf('nobody_id') = 'ffffffffffffffff' (drumate row
-- nobody@local.drumee).
-- ---------------------------------------------------------------
INSERT INTO feature_usage (uid, feature, ctime, hits, volume)
SELECT uid, 'meeting', MIN(first_join), COUNT(*), 0
FROM (
  SELECT s.uid AS uid,
         IFNULL(JSON_VALUE(s.args, '$.room_id'), 'unknown') AS room_id,
         MIN(s.ctime) AS first_join
    FROM services_log s
   INNER JOIN drumate d ON d.id = s.uid
   WHERE s.name = 'conference.join'
     AND s.uid IS NOT NULL AND s.uid <> ''
     AND s.uid NOT IN (get_sysconf('guest_id'), get_sysconf('nobody_id'))
   GROUP BY s.uid, room_id
) AS per_room
GROUP BY uid
ON DUPLICATE KEY UPDATE
  ctime = LEAST(feature_usage.ctime, VALUES(ctime)),
  hits  = VALUES(hits),
  volume = 0;
