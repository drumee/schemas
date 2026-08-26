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
-- ALL FOUR FEATURES ARE HERE, recovered two different ways. upload and meeting
-- read yp directly (mfs_changelog, services_log) and are plain statements. chat
-- and task do not exist in yp at all: messages live in `channel`, one table per
-- WORKSPACE, and `p2p_channel`, one per USER; tasks live in `task`, a common/
-- table present in both. Recovering those means visiting every entity database,
-- which needs dynamic SQL -- hence the temporary procedure at the bottom.
--
-- WHY A CRAWL IS ACCEPTABLE HERE AND NOWHERE ELSE. The read path
-- (analytics.core_function) must never do this: it runs on every page load and
-- would get slower with every signup, which is the entire reason
-- yp.feature_usage exists. A one-time replay carries no such constraint.
-- Measured on stage: ~1,170 entity databases, ~1,550 rows aggregated, well
-- under a second. Do not let the read path's constraint be misread as a ban on
-- the write path doing it once.
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

-- ---------------------------------------------------------------
-- chat and task -- the crawl.
--
-- WHAT IS COUNTED, and why it matches what feature_mark writes live:
--   chat  <db>.channel      workspace messages AND file-thread replies
--                           (channel.post + channel.file_thread_post)
--         <db>.p2p_channel  direct messages (chat.post)
--   task  <db>.task         rows created (task.create)
--
-- p2p_channel IS AN OUTBOX, NOT A MIRROR, and this is the single fact that
-- makes the chat count safe. It looked like a mirror from the service code --
-- _distributeMessage writes through forward_proc to the peer as well -- which
-- would have meant every message counted twice, once in each participant's
-- database. Verified against stage rather than assumed: across every drumate
-- database author_id is ALWAYS that database's owner (0 exceptions), and no
-- non-NULL message_id appears in more than one table. So each sent message
-- exists exactly once, in the sender's own database, and COUNT(*) GROUP BY
-- author_id needs no cross-database de-duplication. If that invariant ever
-- changes this statement double-counts silently -- re-verify before re-running.
--
-- status <> 'draft' because a draft was never sent. Only 'active' rows exist
-- on stage today; the guard is for the day that stops being true.
--
-- THE GUEST EXCLUSION DIFFERS FROM THE UPLOAD STATEMENT ABOVE, deliberately.
-- Upload has none, because it must match funnel_backfill.sql's population or
-- the Core function and Funnel pages disagree about who has uploaded. chat and
-- task have no funnel counterpart to stay consistent with, so the shared DMZ
-- accounts are excluded here for the same reason the meeting statement excludes
-- them: a shared account is not a user. Stage has zero guest-authored chat or
-- task rows today, so this changes nothing now -- it is a guard, not a fix.
-- ---------------------------------------------------------------
DELIMITER $

DROP PROCEDURE IF EXISTS `_feature_usage_crawl`$
CREATE PROCEDURE `_feature_usage_crawl`()
BEGIN
  DECLARE _done   INT DEFAULT 0;
  DECLARE _db     VARCHAR(64);
  DECLARE _tbl    VARCHAR(64);
  DECLARE _guest  VARCHAR(64);
  DECLARE _nobody VARCHAR(64);

  -- The (database, table) list is SNAPSHOT into a temp table before the loop
  -- rather than cursored straight off information_schema: the loop creates and
  -- writes temp tables, which mutates information_schema while such a cursor
  -- would still be open. Snapshotting first removes the question entirely.
  DECLARE cur CURSOR FOR SELECT db_name, tbl FROM _cf_src;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  -- IFNULL, not the bare call. get_sysconf returning NULL would make
  -- QUOTE(NULL) emit the SQL literal NULL, and `author_id NOT IN (NULL, ...)`
  -- evaluates to NULL -- falsy -- excluding EVERY row and replaying an empty
  -- chat/task history over a correct one. '' is the safe stand-in: it can
  -- never match a real uid, and the statements already reject '' anyway.
  SET _guest  = IFNULL(get_sysconf('guest_id'),  '');
  SET _nobody = IFNULL(get_sysconf('nobody_id'), '');

  DROP TEMPORARY TABLE IF EXISTS _cf_src;
  CREATE TEMPORARY TABLE _cf_src (
    db_name VARCHAR(64) NOT NULL,
    tbl     VARCHAR(64) NOT NULL
  ) ENGINE=InnoDB;

  -- INNER JOIN yp.entity scopes the crawl to real workspaces and accounts.
  -- Without it the sweep also picks up factory templates and orphaned schemas
  -- carrying the same table names -- stage has 1336 `channel` tables against
  -- 1167 entity rows, so that difference is not hypothetical.
  INSERT INTO _cf_src (db_name, tbl)
  SELECT t.table_schema, t.table_name
    FROM information_schema.tables t
   INNER JOIN yp.entity e ON e.db_name = t.table_schema
   WHERE t.table_name IN ('channel', 'p2p_channel', 'task');

  DROP TEMPORARY TABLE IF EXISTS _cf_raw;
  CREATE TEMPORARY TABLE _cf_raw (
    uid     VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    feature VARCHAR(8) NOT NULL,
    ctime   INT(11) UNSIGNED NOT NULL,
    KEY idx_uid_feature (uid, feature)
  ) ENGINE=InnoDB;

  OPEN cur;
  crawl: LOOP
    FETCH cur INTO _db, _tbl;
    IF _done THEN LEAVE crawl; END IF;

    IF _tbl = 'task' THEN
      SET @s = CONCAT(
        'INSERT INTO _cf_raw (uid, feature, ctime) ',
        'SELECT created_by, ''task'', ctime FROM `', _db, '`.`task`',
        ' WHERE created_by IS NOT NULL AND created_by <> ''''',
        ' AND created_by NOT IN (', QUOTE(_guest), ',', QUOTE(_nobody), ')');
    ELSE
      SET @s = CONCAT(
        'INSERT INTO _cf_raw (uid, feature, ctime) ',
        'SELECT author_id, ''chat'', ctime FROM `', _db, '`.`', _tbl, '`',
        ' WHERE author_id IS NOT NULL AND author_id <> ''''',
        ' AND status <> ''draft''',
        ' AND author_id NOT IN (', QUOTE(_guest), ',', QUOTE(_nobody), ')');
    END IF;

    PREPARE st FROM @s;
    EXECUTE st;
    DEALLOCATE PREPARE st;
  END LOOP;
  CLOSE cur;

  -- Same shape as the two statements above: absolute totals, MIN(ctime) for
  -- first use, INNER JOIN drumate so a deleted account cannot resurrect.
  -- volume stays 0 -- it means bytes, and only upload has any.
  INSERT INTO yp.feature_usage (uid, feature, ctime, hits, volume)
  SELECT r.uid, r.feature, MIN(r.ctime), COUNT(*), 0
    FROM _cf_raw r
   INNER JOIN yp.drumate d ON d.id = r.uid
   GROUP BY r.uid, r.feature
  ON DUPLICATE KEY UPDATE
    ctime  = LEAST(feature_usage.ctime, VALUES(ctime)),
    hits   = VALUES(hits),
    volume = 0;

  DROP TEMPORARY TABLE IF EXISTS _cf_raw;
  DROP TEMPORARY TABLE IF EXISTS _cf_src;
END $

DELIMITER ;

CALL `_feature_usage_crawl`();
DROP PROCEDURE `_feature_usage_crawl`;
