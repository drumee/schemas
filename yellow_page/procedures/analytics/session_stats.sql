-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- session_stats
--
-- Average session minutes per day, for the Active users page's chart.
--
-- OPTIONALLY BOUNDED BY THE TOPBAR RANGE. `joined_from` / `joined_to` name the
-- days to report; with neither it falls back to `interval` days back from now,
-- which is what the widget sent before and what any older caller still sends.
--
-- AN EVENT BOUND, and correctly so — unlike the funnel's cohort bound. A session
-- happened on a day; asking "how long were sessions in March" is a question
-- about March's events, not about who signed up then.
--
-- ARITY UNCHANGED: this already took `_args JSON`, so the keys can be patched
-- before or after the service without a mismatch.
--
-- THE GAP LOOK-BACK IS DELIBERATELY NOT BOUNDED TO THE FIRST DAY. LAG() needs
-- the event before each one to measure a gap, so the temp table reaches one day
-- further back than the range and the report then drops that day. Without it
-- every session on the first day would look like a fresh start and the average
-- would read short.
-- =========================================================
DROP PROCEDURE IF EXISTS `session_stats`$
CREATE PROCEDURE `session_stats`(
  IN _args JSON
)
BEGIN
  -- ------------------------------------------------------------------
  -- Approximate average session length per active user, by day.
  --
  -- Source: services_log (uid, ctime). We have no explicit session
  -- start/stop. A new session begins on a user's first event or after an
  -- idle gap >= the threshold (_gap, default 30 min). A session's length
  -- is the sum of the within-session gaps (consecutive events < _gap
  -- apart). Per day we report the AVERAGE session length in minutes:
  --   sum(within-session gaps) / number_of_sessions.
  -- This matches the "minutes per session" semantic and excludes idle
  -- time. It remains a heuristic, not exact instrumentation.
  -- ------------------------------------------------------------------
  DECLARE _days INT DEFAULT 7;
  DECLARE _gap INT DEFAULT 1800;
  -- tz: offset in SECONDS so day buckets follow the dashboard timezone.
  DECLARE _tz INT DEFAULT 0;
  DECLARE _from DATE DEFAULT NULL;
  DECLARE _to DATE DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;
  SELECT IFNULL(JSON_VALUE(_args, '$.interval'), 7) INTO _days;
  SELECT IFNULL(JSON_VALUE(_args, '$.tz'), 0) INTO _tz;

  -- Shape-gated before assignment: under STRICT_TRANS_TABLES a malformed value
  -- assigned to a DATE raises rather than reading as absent.
  SELECT JSON_VALUE(_args, '$.joined_from') INTO _raw_from;
  SELECT JSON_VALUE(_args, '$.joined_to') INTO _raw_to;
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  DROP TEMPORARY TABLE IF EXISTS _ev;
  CREATE TEMPORARY TABLE _ev AS
    SELECT
      DATE(FROM_UNIXTIME(ctime + _tz)) AS day,
      ctime - LAG(ctime) OVER (PARTITION BY uid ORDER BY ctime) AS gap
    FROM services_log
    WHERE uid IS NOT NULL
      -- One day further back than asked, so LAG() has the event before the
      -- first reported day; the report below drops it again.
      AND ctime >= IF(_from IS NULL,
                      UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL _days DAY)),
                      UNIX_TIMESTAMP(_from - INTERVAL 1 DAY))
      AND (_to IS NULL OR ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY));

  SELECT
    DATE_FORMAT(day, '%a') AS period,
    day,
    ROUND(
      SUM(IF(gap IS NOT NULL AND gap <= _gap, gap, 0))
      / NULLIF(SUM(IF(gap IS NULL OR gap > _gap, 1, 0)), 0)
      / 60, 1
    ) AS minutes
  FROM _ev
  -- The look-back day is in _ev only to give LAG() something to subtract from.
  WHERE _from IS NULL OR day >= _from
  GROUP BY day
  ORDER BY day ASC;
END$
DELIMITER ;
