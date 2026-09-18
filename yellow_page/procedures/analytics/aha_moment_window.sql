-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- aha_moment_window
--
-- The three Aha-moment signals, optionally bounded.
--
-- TWO DIFFERENT BOUNDS, because the signals do not have the same shape:
--   file_thread and gdrive come from feature_usage, one row per (user, feature)
--     with first-use ctime and running totals -> the *_users counts are bounded
--     to first uses in the range, the hit and volume totals stay lifetime;
--   external sharing comes from secure_share_token, which is ONE ROW PER LINK
--     with its own ctime -> both `shares` and `share_users` are genuinely
--     windowed, counting links created in the range.
--
-- This proc's all-time twin already said so: "COULD be windowed --
-- secure_share_token has ctime". This is that.
-- =========================================================
DROP PROCEDURE IF EXISTS `aha_moment_window`$
CREATE PROCEDURE `aha_moment_window`(
  IN _args JSON
)
BEGIN
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;

  -- Held in a variable and NULL-guarded at every use, as core_function and
  -- funnel_summary do. The guard is not decoration: `email NOT REGEXP NULL`
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
    -- Denominator. Every real account, whether or not it has done any of
    -- this -- a user who has never started a thread is precisely what the
    -- first bar is a share OF, so they must be in this count.
    (SELECT COUNT(*) FROM drumate d0
      WHERE IF(_not_test IS NULL, 1, NOT (d0.email REGEXP _not_test)))
                                                              AS users,

    COUNT(DISTINCT IF(f.feature = 'file_thread' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)), f.uid, NULL)) AS thread_users,
    IFNULL(SUM(IF(f.feature = 'file_thread', f.hits, 0)), 0)   AS thread_hits,

    COUNT(DISTINCT IF(f.feature = 'gdrive' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)), f.uid, NULL))      AS gdrive_users,
    IFNULL(SUM(IF(f.feature = 'gdrive', f.hits, 0)), 0)        AS gdrive_jobs,
    IFNULL(SUM(IF(f.feature = 'gdrive', f.volume, 0)), 0)      AS gdrive_volume,

    -- Users whose gdrive row carries MEASURED bytes. The "Avg GB migrated/user"
    -- card divides by THIS, not by gdrive_users, and the two differ for a real
    -- reason: migrations that completed before the importer started totalling
    -- bytes were replayed from the Bull job records in Redis
    -- (patches/gdrive_usage_backfill.sql), which carry a file count and no byte
    -- count at all. Those rows are honest about adoption and silent about size.
    -- Dividing the byte total by every migrating user would spread real bytes
    -- across users who contributed none and report a number that is wrong in a
    -- direction nobody can see. Zero here means "no measured bytes yet", and
    -- the page renders a dash rather than 0 B.
    COUNT(DISTINCT IF(f.feature = 'gdrive' AND f.volume > 0 AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)), f.uid, NULL))
                                                              AS gdrive_volume_users,

    -- External sharing reads its own durable rows rather than a mirrored
    -- counter: secure_share_token is already one row per link created, with a
    -- creator and a ctime. A second copy in feature_usage would be a second
    -- write and a second answer to the same question that can disagree with
    -- the first after a purge.
    --
    -- REVOKED AND EXPIRED LINKS COUNT. The share happened; taking it back
    -- later does not un-share it, and this page measures whether people reach
    -- outside the workspace at all. Same convention feature_usage applies to
    -- uploaded bytes.
    --
    -- THE JOIN IS BARE ON PURPOSE. creator_id is ascii_general_ci and
    -- drumate.id is a general_ci column too, and ascii coerces into utf8mb4
    -- without a clause -- measured, not assumed. Adding
    -- `COLLATE utf8mb4_general_ci` to an ascii column raises ERROR 1253, so
    -- the obvious "defensive" fix here is itself the bug. The pair that does
    -- raise ERROR 1267 is unicode_ci meeting general_ci; if that ever appears
    -- on either side, fix the column, not this read.
    (SELECT COUNT(DISTINCT s.creator_id) FROM secure_share_token s
      INNER JOIN drumate d1 ON d1.id = s.creator_id
      WHERE IF(_not_test IS NULL, 1, NOT (d1.email REGEXP _not_test))
        AND (_from IS NULL OR s.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR s.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                              AS share_users,
    (SELECT COUNT(*) FROM secure_share_token s2
      INNER JOIN drumate d2 ON d2.id = s2.creator_id
      WHERE IF(_not_test IS NULL, 1, NOT (d2.email REGEXP _not_test))
        AND (_from IS NULL OR s2.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR s2.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                              AS shares,

    -- LIFETIME twins, for the same reason as core_function_window's: the
    -- "Avg x/user" cards divide lifetime hit and volume totals, so they need a
    -- lifetime population. share_users needs none — secure_share_token has a
    -- real date, so shares and share_users are windowed together.
    COUNT(DISTINCT IF(f.feature = 'file_thread', f.uid, NULL)) AS thread_users_all,
    COUNT(DISTINCT IF(f.feature = 'gdrive' AND f.volume > 0, f.uid, NULL))
                                                              AS gdrive_volume_users_all,

    MIN(IF(f.feature = 'gdrive', f.ctime, NULL))              AS since

  FROM feature_usage f
  INNER JOIN drumate d ON d.id = f.uid
  WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test));
END $

DELIMITER ;
