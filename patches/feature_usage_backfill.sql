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
-- RUN IT BEFORE THE SERVICES DEPLOY, or a live event that lands between the
-- backfill and the deploy is counted twice -- once in the replay, once by
-- feature_mark. The window is the deploy itself; ordering closes it.
--
-- ONLY TWO OF THE FOUR FEATURES ARE HERE. Chat and task leave no trace in yp
-- (per-workspace and per-user tables), so there is nothing to replay. They
-- start at zero on deploy day and the page says so.

-- ---------------------------------------------------------------
-- upload -- from mfs_changelog. One media.new row per file, with
-- src.filesize. Chat attachments are already absent: changelog_write
-- returns early for /__chat__/ paths, which is the same exclusion
-- media.js applies before calling feature_mark, so the backfill and
-- the live writer count the same population.
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
-- inner SELECT DISTINCT is the whole point of this statement.
--
-- A NULL room_id means a row written before room_id was carried in
-- args; those collapse into a single 'unknown' meeting per user
-- rather than being dropped, which under-counts by less than
-- discarding them does.
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
   GROUP BY s.uid, room_id
) AS per_room
GROUP BY uid
ON DUPLICATE KEY UPDATE
  ctime = LEAST(feature_usage.ctime, VALUES(ctime)),
  hits  = VALUES(hits),
  volume = 0;
