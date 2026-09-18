-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- cohort_retention
--
-- One row per SEGMENT for the Cohort retention page: all users, referred users,
-- and the four most recent completed signup weeks.
--
-- WHY IT REPLACES referral_retention HERE. That proc answers one segment —
-- referred users — and the page printed "not tracked yet" for everyone else and
-- a mockup row for a weekly cohort. Every figure it was missing is derivable
-- from the same two tables, so nothing needed a new engine.
--
-- D1 / D7 / D30 ARE PER-USER HORIZONS, not a date range. For horizon N a user is
-- ELIGIBLE once their own signup is at least N days old, and RETAINED if they
-- have any services_log activity at or after signup + N days. That is why this
-- page ignores the topbar range: the horizons are measured from each user's own
-- clock, and a range has nothing to move.
--
-- ELIGIBILITY IS WHAT KEEPS A YOUNG COHORT HONEST. This week's signups are not
-- eligible for D7 yet, so their D7 denominator is 0 and the page prints a dash
-- rather than a 0% that would read as total collapse.
--
-- CURRENTLY WAU / MAU are a different question from the horizons: the share of
-- the segment active in the CURRENT rolling 7 and 28 days, whenever they joined.
--
-- ONE PASS OVER THE USERS, into a temp table, because the segments overlap — a
-- referred user signing up last week belongs to three rows — and running the
-- same EXISTS subqueries once per segment would be the same work three times.
-- =========================================================
DROP PROCEDURE IF EXISTS `cohort_retention`$
CREATE PROCEDURE `cohort_retention`(
  IN _args JSON
)
BEGIN
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;
  DECLARE _now INT;
  DECLARE _weeks INT DEFAULT 4;
  -- LIMIT takes a variable but not an expression, hence this rather than
  -- `LIMIT 2 + _weeks` at the bottom.
  DECLARE _rows INT DEFAULT 6;

  -- Held in a variable and NULL-guarded at every use: `email NOT REGEXP NULL`
  -- is NULL, which is falsy, so an unset pattern would exclude EVERY user and
  -- report an empty page rather than an unfiltered one.
  SET _not_test = analytics_test_email_regexp();
  SET _now = UNIX_TIMESTAMP();
  SELECT IFNULL(JSON_VALUE(_args, '$.weeks'), 4) INTO _weeks;
  SET _rows = 2 + GREATEST(IFNULL(_weeks, 4), 0);

  DROP TEMPORARY TABLE IF EXISTS _cohort_u;
  CREATE TEMPORARY TABLE _cohort_u AS
    SELECT
      d.id,
      (JSON_VALUE(d.profile, '$.ref') IS NOT NULL)                     AS referred,
      DATE(FROM_UNIXTIME(e.ctime))                                     AS signup_day,
      YEARWEEK(FROM_UNIXTIME(e.ctime), 3)                              AS signup_week,
      (e.ctime <= _now - 86400)                                        AS elig1,
      (e.ctime <= _now - 86400 AND EXISTS(
        SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= e.ctime + 86400))    AS ret1,
      (e.ctime <= _now - 604800)                                       AS elig7,
      (e.ctime <= _now - 604800 AND EXISTS(
        SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= e.ctime + 604800))   AS ret7,
      (e.ctime <= _now - 2592000)                                      AS elig30,
      (e.ctime <= _now - 2592000 AND EXISTS(
        SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= e.ctime + 2592000))  AS ret30,
      -- The CURRENT rolling windows, whenever the user joined.
      EXISTS(SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= _now - 604800)  AS wau,
      EXISTS(SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= _now - 2419200) AS mau
    FROM drumate d
    INNER JOIN entity e ON e.id = d.id
    WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test));

  -- `sort` fixes the reading order: everyone, then referred, then the weeks
  -- newest first. `label` is built here rather than in the page so the segment
  -- and its name cannot drift apart.
  SELECT * FROM (
    SELECT 0 AS sort, 'all' AS segment, 'All users' AS label,
           COUNT(*) AS users,
           IFNULL(SUM(elig1),0) AS eligible_d1,  IFNULL(SUM(ret1),0) AS retained_d1,
           IFNULL(SUM(elig7),0) AS eligible_d7,  IFNULL(SUM(ret7),0) AS retained_d7,
           IFNULL(SUM(elig30),0) AS eligible_d30, IFNULL(SUM(ret30),0) AS retained_d30,
           IFNULL(SUM(wau),0) AS wau, IFNULL(SUM(mau),0) AS mau
      FROM _cohort_u

    UNION ALL
    SELECT 1, 'referred', 'Referral (existing)',
           COUNT(*),
           IFNULL(SUM(elig1),0), IFNULL(SUM(ret1),0),
           IFNULL(SUM(elig7),0), IFNULL(SUM(ret7),0),
           IFNULL(SUM(elig30),0), IFNULL(SUM(ret30),0),
           IFNULL(SUM(wau),0), IFNULL(SUM(mau),0)
      FROM _cohort_u WHERE referred = 1

    UNION ALL
    -- The most recent COMPLETED weeks. The current week is excluded on purpose:
    -- it is still filling, so its counts would move every time the page is
    -- opened and could only fall as a share.
    SELECT * FROM (
      SELECT 2 + ROW_NUMBER() OVER (ORDER BY signup_week DESC),
             CONCAT('week:', signup_week),
             CONCAT('Wk', LPAD(WEEK(MIN(signup_day), 3), 2, '0'), '-', YEAR(MIN(signup_day))),
             COUNT(*),
             IFNULL(SUM(elig1),0), IFNULL(SUM(ret1),0),
             IFNULL(SUM(elig7),0), IFNULL(SUM(ret7),0),
             IFNULL(SUM(elig30),0), IFNULL(SUM(ret30),0),
             IFNULL(SUM(wau),0), IFNULL(SUM(mau),0)
        FROM _cohort_u
       WHERE signup_week < YEARWEEK(CURDATE(), 3)
       GROUP BY signup_week
       ORDER BY signup_week DESC
       LIMIT 100
    ) AS wk LIMIT 100
  ) AS segments
  ORDER BY sort
  LIMIT _rows;

  DROP TEMPORARY TABLE IF EXISTS _cohort_u;
END $

DELIMITER ;
