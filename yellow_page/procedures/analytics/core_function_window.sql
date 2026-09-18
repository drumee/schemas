-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- core_function_window
--
-- Core-function adoption, optionally bounded to an ADOPTION COHORT.
--
-- WHAT THE BOUND MEANS, AND WHAT IT CANNOT MEAN. feature_usage holds ONE ROW
-- PER (user, feature): `ctime` is stamped the FIRST time that user touched the
-- feature and never moves, and `hits`/`volume` are running totals that
-- feature_mark adds to (`hits = hits + n`). There is no per-day history, so
-- "who used chat in March" is not answerable from this table at all. What IS
-- answerable is "who first used chat in March", and that is what the window
-- does here.
--
-- SO THE COUNTS ARE BOUNDED AND THE TOTALS ARE NOT. Every *_users figure counts
-- first-uses inside the range; every *_hits / *_volume figure stays lifetime,
-- because a running total cannot be cut at a date. The page labels them so.
--
-- `users` (the denominator) and `since` stay all-time too: the adoption bars
-- read "of everyone on the platform, this many took it up in the range", and
-- `since` says when measurement began, which no range changes.
-- =========================================================
DROP PROCEDURE IF EXISTS `core_function_window`$
CREATE PROCEDURE `core_function_window`(
  IN _args JSON
)
BEGIN
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;

  -- Held in a variable and NULL-guarded at every use, as funnel_summary and
  -- the reward procs do. The guard is not decoration: `email NOT REGEXP NULL`
  -- evaluates to NULL, which is falsy, so an unset pattern would exclude
  -- EVERY user and report an empty page rather than an unfiltered one.
  DECLARE _from DATE DEFAULT NULL;
  DECLARE _to DATE DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;

  -- Shape-gated before assignment: under STRICT_TRANS_TABLES a malformed value
  -- assigned to a DATE raises rather than reading as absent.
  SELECT JSON_VALUE(_args, "$.joined_from") INTO _raw_from;
  SELECT JSON_VALUE(_args, "$.joined_to") INTO _raw_to;
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  SET _not_test = analytics_test_email_regexp();

  SELECT
    -- Denominator. Every real account, whether or not it has a usage row --
    -- a user who has never uploaded is precisely what the Upload bar is a
    -- share OF, so they must be in this count.
    (SELECT COUNT(*) FROM drumate d
      WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test)))
                                                          AS users,

    COUNT(DISTINCT IF(f.feature = 'upload'  AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)), f.uid, NULL)) AS upload_users,
    COUNT(DISTINCT IF(f.feature = 'chat' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)),    f.uid, NULL)) AS chat_users,
    COUNT(DISTINCT IF(f.feature = 'task' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)),    f.uid, NULL)) AS task_users,
    COUNT(DISTINCT IF(f.feature = 'meeting' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)), f.uid, NULL)) AS meeting_users,

    -- Used all four. Counted from the same rows as the bars above rather than
    -- from a second query, so the intersection can never exceed its smallest
    -- component -- which a separately-filtered query could, if the two ran
    -- either side of a write.
    --
    -- THE IN-LIST IS LOAD-BEARING, NOT DECORATION. feature_usage is no longer
    -- a table with exactly four rows per fully-adopted user -- it also carries
    -- Aha-moment signals (file_thread, gdrive, and whatever gets added next).
    -- COUNT(DISTINCT f2.feature) with no filter counts ALL of those keys, so a
    -- user with all four core features plus one Aha-moment row would need 5
    -- distinct features to clear this HAVING, and would silently drop out of
    -- "used all 4 core features" -- inverted-selective, since the most
    -- engaged users are exactly the ones who also trip Aha-moment signals.
    -- The next person adding a feature key to this table must add it here
    -- too, in the enum below, ONLY if it is meant to be one of the four core
    -- features this card counts -- otherwise leave it out, the same way
    -- file_thread and gdrive are left out now.
    (SELECT COUNT(*) FROM (
       SELECT f2.uid FROM feature_usage f2
       INNER JOIN drumate d2 ON d2.id = f2.uid
       WHERE IF(_not_test IS NULL, 1, NOT (d2.email REGEXP _not_test))
         AND (_from IS NULL OR f2.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f2.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY))
       GROUP BY f2.uid
       HAVING COUNT(DISTINCT IF(f2.feature IN ('upload','chat','task','meeting'), f2.feature, NULL)) = 4
     ) AS quad)                                            AS full_feature_users,

    -- LIFETIME twins of the four counts above. The bars show adoption INSIDE
    -- the range; the "Avg x/user" cards divide a lifetime hit total, and
    -- dividing that by a windowed population would answer nothing — lifetime
    -- messages over the users who joined chat this week. Both populations are
    -- needed, so both are returned, and the page labels the averages all-time.
    COUNT(DISTINCT IF(f.feature = 'upload',  f.uid, NULL)) AS upload_users_all,
    COUNT(DISTINCT IF(f.feature = 'chat',    f.uid, NULL)) AS chat_users_all,
    COUNT(DISTINCT IF(f.feature = 'task',    f.uid, NULL)) AS task_users_all,
    COUNT(DISTINCT IF(f.feature = 'meeting', f.uid, NULL)) AS meeting_users_all,

    -- ---- Uploads, FROM THE EVENT TRAIL ---------------------------------
    -- The one core feature yp records event by event: mfs_changelog keeps a row
    -- per media.new with its own timestamp, so "uploads in the range" is a real
    -- question here, unlike chat, task and meeting -- whose messages, tasks and
    -- participant rows live in per-workspace/per-user tables or are deleted on
    -- leave, which is why feature_usage exists at all.
    --
    -- So THESE three follow the range and the *_hits below do not. They are
    -- also a different measure from feature_usage's upload counters and will not
    -- match them: the changelog has every upload, feature_usage only those by
    -- users it has a row for. The page uses these for Total uploads and Avg
    -- storage/user, and the older pair is kept for callers that still read it.
    --
    -- One scan of media.new rows with a JSON read per row; on stage that is
    -- ~12k rows in under 40ms, bounded further whenever a range is set.
    (SELECT COUNT(*) FROM mfs_changelog m
       INNER JOIN drumate dm ON dm.id = m.uid
      WHERE m.event = 'media.new'
        AND IF(_not_test IS NULL, 1, NOT (dm.email REGEXP _not_test))
        AND (_from IS NULL OR m.timestamp >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR m.timestamp < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))                                            AS upload_events,

    (SELECT IFNULL(SUM(CAST(JSON_VALUE(m.src, '$.filesize') AS UNSIGNED)), 0)
       FROM mfs_changelog m
       INNER JOIN drumate dm ON dm.id = m.uid
      WHERE m.event = 'media.new'
        AND IF(_not_test IS NULL, 1, NOT (dm.email REGEXP _not_test))
        AND (_from IS NULL OR m.timestamp >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR m.timestamp < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))                                            AS upload_event_volume,

    (SELECT COUNT(DISTINCT m.uid) FROM mfs_changelog m
       INNER JOIN drumate dm ON dm.id = m.uid
      WHERE m.event = 'media.new'
        AND IF(_not_test IS NULL, 1, NOT (dm.email REGEXP _not_test))
        AND (_from IS NULL OR m.timestamp >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR m.timestamp < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))                                            AS upload_event_users,

    -- ---- Lifetime running totals, which no range can cut ----------------
    IFNULL(SUM(IF(f.feature = 'upload',  f.hits,   0)), 0) AS upload_hits,
    IFNULL(SUM(IF(f.feature = 'upload',  f.volume, 0)), 0) AS upload_volume,
    IFNULL(SUM(IF(f.feature = 'chat',    f.hits,   0)), 0) AS chat_hits,
    IFNULL(SUM(IF(f.feature = 'task',    f.hits,   0)), 0) AS task_hits,
    IFNULL(SUM(IF(f.feature = 'meeting', f.hits,   0)), 0) AS meeting_hits,

    -- When live collection began. Upload AND meeting are excluded because
    -- both were backfilled (feature_usage_backfill.sql): their earliest
    -- ctime is the oldest historical file/join on the install, which says
    -- nothing about when this page started measuring. Only chat and task
    -- have no backfill, so only they define the honest start of collection.
    MIN(IF(f.feature IN ('chat', 'task'), f.ctime, NULL))    AS since

  FROM feature_usage f
  INNER JOIN drumate d ON d.id = f.uid
  WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test));
END $

DELIMITER ;
