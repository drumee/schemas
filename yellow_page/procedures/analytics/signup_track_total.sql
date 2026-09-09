DELIMITER $

-- =========================================================
-- signup_track_total
--
-- How many tracked signups there are: `matched` under the filter in force and
-- `total` with none.
--
-- WHY A SEPARATE PROC: signup_track_list returns one PAGE and the framework's
-- list widget does not synthesise a count, so the UI cannot say how many
-- signups there are from the data it holds. Same reasoning that gave
-- users_total and utm_link_total their own services.
--
-- THE FILTERS ARE COPIED FROM signup_track_list AND MUST STAY COPIED, down to
-- the declared types, so a longer filter truncates identically in both and the
-- count cannot disagree with the rows. users_total says the same at length.
--
-- Also returns `attributed` — how many of the matched rows carry a campaign at
-- all. That is the number that says whether attribution is working: it was
-- zero for every OAuth signup until the oauth_state columns landed, and
-- nothing on the dashboard would have shown it.
-- =========================================================
DROP PROCEDURE IF EXISTS `signup_track_total`$
CREATE PROCEDURE `signup_track_total`(
  IN _args JSON
)
BEGIN
  DECLARE _campaign VARCHAR(64) DEFAULT NULL;
  DECLARE _source VARCHAR(64) DEFAULT NULL;
  DECLARE _method VARCHAR(16) DEFAULT NULL;
  DECLARE _from VARCHAR(32) DEFAULT NULL;
  DECLARE _to VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;

  SELECT NULLIF(JSON_VALUE(_args, "$.campaign"), '') INTO _campaign;
  SELECT NULLIF(JSON_VALUE(_args, "$.source"), '') INTO _source;
  SELECT NULLIF(JSON_VALUE(_args, "$.method"), '') INTO _method;
  SELECT JSON_VALUE(_args, "$.joined_from") INTO _raw_from;
  SELECT JSON_VALUE(_args, "$.joined_to") INTO _raw_to;
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  SELECT
    (SELECT COUNT(*) FROM yp.signup_track) AS total,
    COUNT(*) AS matched,
    -- IFNULL, because SUM over no rows is NULL and the dashboard renders a
    -- NULL as "—" (did not arrive) and a 0 as "none". On an empty table the
    -- true answer is that nothing is attributed, which is a 0.
    IFNULL(SUM(t.campaign IS NOT NULL), 0) AS attributed
  FROM yp.signup_track t
  WHERE IF(_campaign IS NULL, 1, t.campaign = _campaign)
    AND IF(_source IS NULL, 1, t.source = _source)
    AND IF(_method IS NULL, 1, t.method = _method)
    AND IF(_from IS NULL, 1, t.ctime >= UNIX_TIMESTAMP(_from))
    AND IF(_to IS NULL, 1, t.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY));
END$

DELIMITER ;
