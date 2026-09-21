-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- extended_window
--
-- The two intent signals, optionally bounded to an ADOPTION COHORT. Same rule
-- and same reason as core_function_window: feature_usage carries first-use plus
-- running totals, so *_users can be bounded to first clicks inside the range and
-- *_hits cannot be bounded at all.
-- =========================================================
DROP PROCEDURE IF EXISTS `extended_window`$
CREATE PROCEDURE `extended_window`(
  IN _args JSON
)
BEGIN
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;

  -- Held in a variable and NULL-guarded at every use, as core_function and
  -- aha_moment do. The guard is not decoration: `email NOT REGEXP NULL`
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
    -- Denominator. Every real account, whether or not it has clicked
    -- anything -- a user who never opened billing is precisely what the
    -- first bar is a share OF, so they must be in this count.
    (SELECT COUNT(*) FROM drumate d0
      WHERE IF(_not_test IS NULL, 1, NOT (d0.email REGEXP _not_test)))
                                                                   AS users,

    COUNT(DISTINCT IF(f.feature = 'upgrade_click' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)),    f.uid, NULL)) AS upgrade_users,
    IFNULL(SUM(IF(f.feature = 'upgrade_click',    f.hits, 0)), 0)   AS upgrade_hits,

    COUNT(DISTINCT IF(f.feature = 'selfhosted_click' AND (_from IS NULL OR f.ctime >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR f.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)), f.uid, NULL)) AS selfhosted_users,
    IFNULL(SUM(IF(f.feature = 'selfhosted_click', f.hits, 0)), 0)   AS selfhosted_hits,

    MIN(IF(f.feature IN ('upgrade_click', 'selfhosted_click'), f.ctime, NULL))
                                                                   AS since

  FROM feature_usage f
  INNER JOIN drumate d ON d.id = f.uid
  WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test));
END $

DELIMITER ;
