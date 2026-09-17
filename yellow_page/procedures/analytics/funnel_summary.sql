-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows. A
-- procedure there is one no documented tooling can apply (see 8a4a082, which
-- moved signup_track for the same reason).
DELIMITER $
-- =========================================================
-- funnel_summary
--
-- One-row tally of the activation funnel, for the dashboard's
-- Activation > Funnel page.
--
-- ALL TIME, NO ARGUMENTS. Every other page here is windowed by
-- the topbar chip; this one deliberately is not, and the page
-- says so in its own caption rather than leaving a chip that
-- silently does nothing (which is exactly the bug the growth
-- chart shipped with -- see apiArgs in analytics-ui utils.js).
-- If a windowed version is ever wanted, it should take a SIGNUP
-- COHORT bound (entity.ctime BETWEEN ...), not an event bound:
-- counting milestones that merely OCCURRED in a window puts a
-- March signup who activated in August into Activated but not
-- into Signup, and the funnel stops being monotonic.
--
-- THE SHAPE IS NOT A LINE, and the counts reflect that.
-- Signup -> Onboarded is sequential. `folder` and `upload` are
-- two INDEPENDENT flags that can land in either order, so they
-- are counted separately and neither is a subset of the other.
-- `activated` is both, and is written by funnel_mark rather than
-- computed here -- the read side must not carry a second copy of
-- the rule the write side already applies.
--
-- INNER JOIN entity, and the test-email exclusion, because this
-- has to agree with the Signup box: that number is users_real,
-- which is defined exactly this way in analytics-server
-- get_env. A stage counted over a wider population than its own
-- denominator produces percentages over 100.
--
-- THE FILTER IS THE FUNCTION, NOT A LITERAL. Reading
-- analytics_test_email_regexp() rather than taking the pattern
-- as an argument is what lets this proc be patched before or
-- after the service without an arity mismatch, and what makes
-- the ops override in yp.sys_conf reach SQL and Node together.
-- See that function's own header; do not inline the pattern.
-- =========================================================
DROP PROCEDURE IF EXISTS `funnel_summary`$
CREATE PROCEDURE `funnel_summary`()
BEGIN
  DECLARE _median INT(11) DEFAULT NULL;
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;

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
     AND IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test));

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
  WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test));
END $

DELIMITER ;
