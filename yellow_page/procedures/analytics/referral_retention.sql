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
  -- ------------------------------------------------------------------
  DECLARE _now INT;
  SET _now = UNIX_TIMESTAMP();

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
  ) t;
END$
DELIMITER ;
