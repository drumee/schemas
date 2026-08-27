-- File: schemas/patches/aha_usage_backfill.sql
-- Purpose: seed yp.feature_usage with the file-thread history that IS
--          recoverable, so the Aha moment page does not open reading zero for
--          an install that has been stitching chat to files for months.
--
-- RE-RUNNABLE. The upsert writes ABSOLUTE totals (hits = VALUES(hits)), the
-- opposite of feature_mark's incremental contract, because a replay knows the
-- true total whereas a live event knows only its own delta.
--
-- ONE SIGNAL, NOT TWO. 'gdrive' is deliberately absent and cannot be added:
-- migration job state lives in Bull (Redis) and completed jobs leave nothing
-- behind. Deriving it from `GoogleDriveMigration` wrapper folders was
-- considered and rejected -- folder-window imports launch with direct:1 and
-- land with no wrapper at all, so the figure would silently omit them.
-- The Google migration bar starts at deploy day, and the page says so.
--
-- DELETED THREADS COUNT. status='deleted' is included: the thread was started,
-- and deleting it later does not un-start it. Same convention feature_usage
-- already applies to uploaded bytes ("deleting a file does not decrease it").
--
-- WHY A CRAWL IS ACCEPTABLE HERE AND NOWHERE ELSE. `file_thread` is one table
-- per WORKSPACE database, so the read path (analytics.aha_moment) must never
-- enumerate them -- it runs on every page load and would slow with every
-- signup, which is the entire reason yp.feature_usage exists. A one-time
-- replay carries no such constraint. Same trade feature_usage_backfill.sql
-- makes for chat and task.
--
-- =========================================================================
-- NEVER ADD THIS FILE TO patches/manifest.txt.
--
-- The manifest is applied wholesale on every patch run. Because this file's
-- upsert writes ABSOLUTE totals, a later unrelated manifest run that happened
-- to include it would reset every live file_thread counter back to the totals
-- captured at replay time -- silently discarding every thread started since.
-- Apply it exactly once, by hand: mysql yp < patches/aha_usage_backfill.sql
-- =========================================================================

DELIMITER $

DROP PROCEDURE IF EXISTS `_aha_usage_crawl`$
CREATE PROCEDURE `_aha_usage_crawl`()
BEGIN
  DECLARE _done   INT DEFAULT 0;
  DECLARE _db     VARCHAR(64);
  DECLARE _guest  VARCHAR(64);
  DECLARE _nobody VARCHAR(64);

  -- The database list is SNAPSHOT into a temp table before the loop rather
  -- than cursored straight off information_schema: the loop creates and writes
  -- temp tables, which mutates information_schema while such a cursor would
  -- still be open. Snapshotting first removes the question entirely.
  DECLARE cur CURSOR FOR SELECT db_name FROM _ah_src;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  -- IFNULL, not the bare call. get_sysconf returning NULL would make
  -- QUOTE(NULL) emit the SQL literal NULL, and `created_by NOT IN (NULL, ...)`
  -- evaluates to NULL -- falsy -- excluding EVERY row and replaying an empty
  -- history over a correct one. '' can never match a real uid.
  SET _guest  = IFNULL(get_sysconf('guest_id'),  '');
  SET _nobody = IFNULL(get_sysconf('nobody_id'), '');

  DROP TEMPORARY TABLE IF EXISTS _ah_src;
  CREATE TEMPORARY TABLE _ah_src (
    db_name VARCHAR(64) NOT NULL
  ) ENGINE=InnoDB;

  -- INNER JOIN yp.entity scopes the crawl to real workspaces. Without it the
  -- sweep also picks up factory templates and orphaned schemas carrying the
  -- same table name -- on stage that difference is over a hundred databases.
  INSERT INTO _ah_src (db_name)
  SELECT t.table_schema
    FROM information_schema.tables t
   INNER JOIN yp.entity e ON e.db_name = t.table_schema
   WHERE t.table_name = 'file_thread';

  DROP TEMPORARY TABLE IF EXISTS _ah_raw;
  CREATE TEMPORARY TABLE _ah_raw (
    uid   VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    ctime INT(11) UNSIGNED NOT NULL,
    KEY idx_uid (uid)
  ) ENGINE=InnoDB;

  OPEN cur;
  crawl: LOOP
    FETCH cur INTO _db;
    IF _done THEN LEAVE crawl; END IF;

    SET @s = CONCAT(
      'INSERT INTO _ah_raw (uid, ctime) ',
      'SELECT created_by, ctime FROM `', _db, '`.`file_thread`',
      ' WHERE created_by IS NOT NULL AND created_by <> ''''',
      ' AND created_by NOT IN (', QUOTE(_guest), ',', QUOTE(_nobody), ')');
    PREPARE st FROM @s;
    EXECUTE st;
    DEALLOCATE PREPARE st;
  END LOOP;
  CLOSE cur;

  -- Absolute totals, MIN(ctime) for first use, INNER JOIN drumate so a deleted
  -- account cannot resurrect. volume stays 0 -- it means bytes, and a thread
  -- has none.
  INSERT INTO yp.feature_usage (uid, feature, ctime, hits, volume)
  SELECT r.uid, 'file_thread', MIN(r.ctime), COUNT(*), 0
    FROM _ah_raw r
   INNER JOIN yp.drumate d ON d.id = r.uid
   GROUP BY r.uid
  ON DUPLICATE KEY UPDATE
    ctime  = LEAST(feature_usage.ctime, VALUES(ctime)),
    hits   = VALUES(hits),
    volume = 0;

  DROP TEMPORARY TABLE IF EXISTS _ah_raw;
  DROP TEMPORARY TABLE IF EXISTS _ah_src;
END $

DELIMITER ;

CALL _aha_usage_crawl();
DROP PROCEDURE IF EXISTS `_aha_usage_crawl`;
