-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows. A
-- procedure there is one no documented tooling can apply (see 8a4a082, which
-- moved signup_track for the same reason).
DELIMITER $
-- =========================================================
-- funnel_summary_window
--
-- One-row tally of the activation funnel, for the dashboard's
-- Activation > Funnel page.
--
-- BOUNDED BY SIGNUP COHORT, OPTIONALLY. `_args` may carry
-- `joined_from` / `joined_to` (YYYY-MM-DD, either may stand
-- alone); with neither it reports ALL TIME, which is what the
-- Funnel page sends -- that page is all-time by design and says
-- so in its own caption. The Overview's funnel row sends the
-- topbar window.
--
-- THE BOUND IS ON entity.ctime, NEVER ON A MILESTONE'S ctime.
-- Counting milestones that merely OCCURRED in a window puts a
-- March signup who activated in August into Activated but not
-- into Signup, and the funnel stops being monotonic -- Activated
-- exceeds its own denominator and shares go over 100%. Bounding
-- the cohort keeps every stage a subset of Signup.
--
-- The end day is INCLUDED: half-open against the following
-- midnight, the idiom distribution_signups already uses.
--
-- A SEPARATE PROCEDURE, NOT A NEW ARGUMENT ON funnel_summary.
-- MariaDB has no default parameters, so giving funnel_summary()
-- an argument breaks every caller that still sends none -- in
-- EITHER deploy order. Stage has one shared yp and several
-- endpoints (main, liam, huan on 2026-09-17) whose
-- analytics-server calls funnel_summary() bare; changing its arity
-- would have broken their Funnel page on patch. So funnel_summary()
-- keeps its signature and delegates here with no window, and only
-- servers that know about the window call this.
--
-- DEPLOY ORDER: patch this BEFORE shipping a server that calls it.
-- A procedure missing outright returns an empty 200 but
-- desynchronises the shared connection and hangs a concurrent
-- request. Patching first breaks nothing.
-- =========================================================
DROP PROCEDURE IF EXISTS `funnel_summary_window`$
CREATE PROCEDURE `funnel_summary_window`(
  IN _args JSON
)
BEGIN
  DECLARE _median INT(11) DEFAULT NULL;
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;
  DECLARE _from DATE DEFAULT NULL;
  DECLARE _to DATE DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;

  -- Shape-gated before assignment, as signup_track_list and
  -- distribution_signups gate theirs: under STRICT_TRANS_TABLES a malformed
  -- value assigned to a DATE raises rather than reading as absent.
  SELECT JSON_VALUE(_args, "$.joined_from") INTO _raw_from;
  SELECT JSON_VALUE(_args, "$.joined_to") INTO _raw_to;
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  -- Held in a variable and NULL-guarded at every use, exactly as
  -- reward_tracking / reward_summary / distribution_signups do. The guard is
  -- not decoration: `email NOT REGEXP NULL` evaluates to NULL, which is falsy,
  -- so an unset pattern would exclude EVERY user and report an empty funnel
  -- rather than an unfiltered one.
  SET _not_test = analytics_test_email_regexp();

  -- Median seconds from signup to activation, over activated real users.
  --
  -- A SEPARATE STATEMENT because MEDIAN is a window function: it yields the
  -- same value on every row rather than collapsing them, so it cannot sit
  -- beside the COUNT()s below. SELECT DISTINCT ... INTO takes the one value
  -- back out; with no activated users there are no rows at all and _median is
  -- left NULL, which the dashboard renders as a dash.
  --
  -- act.ctime >= e.ctime guards the median against a negative sample. It
  -- should be unreachable -- a changelog row cannot predate the account that
  -- wrote it -- but a single restored or hand-edited row would otherwise drag
  -- the median without anything on the page looking wrong.
  SELECT DISTINCT MEDIAN(act.ctime - e.ctime) OVER ()
    INTO _median
    FROM funnel_milestone act
   INNER JOIN drumate d ON d.id = act.uid
   INNER JOIN entity  e ON e.id = d.id
   WHERE act.milestone = 'activated'
     AND act.ctime >= e.ctime
     AND IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test))
     AND IF(_from IS NULL, 1, e.ctime >= UNIX_TIMESTAMP(_from))
     AND IF(_to IS NULL, 1, e.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY));

  SELECT
    COUNT(*)                          AS signup,
    COUNT(onb.uid)                    AS onboarded,
    COUNT(fld.uid)                    AS folder,
    COUNT(upl.uid)                    AS upload,
    COUNT(act.uid)                    AS activated,
    -- How many of the `onboarded` above carry a stand-in timestamp rather
    -- than a measured one (backfilled accounts -- see patches/funnel_backfill
    -- in the schemas repo). Surfaced so the page can say so instead of
    -- presenting an estimate as a measurement.
    IFNULL(SUM(onb.approx), 0)        AS onboarded_approx,
    _median                           AS median_activate_sec
  FROM drumate d
  INNER JOIN entity e ON e.id = d.id
  LEFT JOIN funnel_milestone onb ON onb.uid = d.id AND onb.milestone = 'onboarded'
  LEFT JOIN funnel_milestone fld ON fld.uid = d.id AND fld.milestone = 'folder'
  LEFT JOIN funnel_milestone upl ON upl.uid = d.id AND upl.milestone = 'upload'
  LEFT JOIN funnel_milestone act ON act.uid = d.id AND act.milestone = 'activated'
  WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test))
    -- The same cohort bound as the median above: the two must describe one
    -- population, or the median is of users the counts beside it exclude.
    AND IF(_from IS NULL, 1, e.ctime >= UNIX_TIMESTAMP(_from))
    AND IF(_to IS NULL, 1, e.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY));
END $

DELIMITER ;
