-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows. A
-- procedure there is one no documented tooling can apply (see 8a4a082, which
-- moved signup_track for the same reason).
DELIMITER $
DROP PROCEDURE IF EXISTS `referral_retention`$
CREATE PROCEDURE `referral_retention`(
  IN _args JSON
)
BEGIN
  -- ------------------------------------------------------------------
  -- D1 / D7 / D30 retention of referred users. For each horizon N, a
  -- user is "eligible" once they signed up at least N days ago, and
  -- "retained" if they have any services_log activity at or after
  -- signup + N days (i.e. they came back). Returns eligible + retained
  -- counts per horizon (single row); the UI shows retained/eligible %.
  --
  -- OPTIONALLY BOUNDED BY SIGNUP COHORT: `joined_from` / `joined_to` in
  -- _args (YYYY-MM-DD, either may stand alone; neither = all referred
  -- users, which is what the Cohort page sends). The bound is on
  -- entity.ctime -- WHEN THEY JOINED -- never on when they came back, so
  -- "retained" stays a subset of "eligible". The end day is included.
  --
  -- A JSON key, not a new argument: arity is unchanged, so this can be
  -- patched before or after the service without a mismatch.
  -- ------------------------------------------------------------------
  DECLARE _now INT;
  DECLARE _from DATE DEFAULT NULL;
  DECLARE _to DATE DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;
  SET _now = UNIX_TIMESTAMP();

  -- Shape-gated before assignment: under STRICT_TRANS_TABLES a malformed
  -- value assigned to a DATE raises rather than reading as absent.
  SELECT JSON_VALUE(_args, "$.joined_from") INTO _raw_from;
  SELECT JSON_VALUE(_args, "$.joined_to") INTO _raw_to;
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  SELECT
    IFNULL(SUM(elig1), 0)  AS eligible_d1,  IFNULL(SUM(ret1), 0)  AS retained_d1,
    IFNULL(SUM(elig7), 0)  AS eligible_d7,  IFNULL(SUM(ret7), 0)  AS retained_d7,
    IFNULL(SUM(elig30), 0) AS eligible_d30, IFNULL(SUM(ret30), 0) AS retained_d30
  FROM (
    SELECT
      d.id,
      (e.ctime <= _now - 86400)  AS elig1,
      (e.ctime <= _now - 86400  AND EXISTS(SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= e.ctime + 86400))  AS ret1,
      (e.ctime <= _now - 604800) AS elig7,
      (e.ctime <= _now - 604800 AND EXISTS(SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= e.ctime + 604800)) AS ret7,
      (e.ctime <= _now - 2592000) AS elig30,
      (e.ctime <= _now - 2592000 AND EXISTS(SELECT 1 FROM services_log s WHERE s.uid = d.id AND s.ctime >= e.ctime + 2592000)) AS ret30
    FROM drumate d INNER JOIN entity e ON e.id = d.id
    WHERE JSON_VALUE(d.profile, '$.ref') IS NOT NULL
      AND IF(_from IS NULL, 1, e.ctime >= UNIX_TIMESTAMP(_from))
      AND IF(_to IS NULL, 1, e.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY))
  ) t;
END$
DELIMITER ;
