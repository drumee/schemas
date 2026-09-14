DELIMITER $

-- =========================================================
-- signup_track_list
--
-- One page of tracked signups, newest first.
--
-- SHAPED LIKE users_list, which every paged table here follows: `page_at` with
-- `page` as the fallback (both names are in use — the list widget sends
-- page_at, older callers send page, and accepting only `page` silently pages
-- the widget back to 1), `pagelength` defaulting to 45, and COUNT(*) OVER ()
-- AS matches so the count costs one pass rather than a second query with this
-- one's filters duplicated into it.
--
-- LEFT JOIN to drumate, so a row outlives the account it describes — which is
-- the entire reason signup_track exists rather than a profile key. A deleted
-- user's signup still counts toward the campaign that produced it; the email
-- column on the row is what still names them.
-- =========================================================
DROP PROCEDURE IF EXISTS `signup_track_list`$
CREATE PROCEDURE `signup_track_list`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _column VARCHAR(20) DEFAULT 'date';
  DECLARE _order VARCHAR(20) DEFAULT 'desc';
  DECLARE _campaign VARCHAR(64) DEFAULT NULL;
  DECLARE _source VARCHAR(64) DEFAULT NULL;
  DECLARE _method VARCHAR(16) DEFAULT NULL;
  DECLARE _from VARCHAR(32) DEFAULT NULL;
  DECLARE _to VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;
  DECLARE _page INTEGER DEFAULT 1;

  SELECT IFNULL(JSON_VALUE(_args, "$.column"), 'date') INTO _column;
  SELECT IFNULL(JSON_VALUE(_args, "$.order"), 'desc') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, "$.page_at"),
                IFNULL(JSON_VALUE(_args, "$.page"), 1)) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pagelength"), 45) INTO @rows_per_page;
  -- Empty string is no filter, not a filter for the empty value: the UI's
  -- "All campaigns" option posts ''.
  SELECT NULLIF(JSON_VALUE(_args, "$.campaign"), '') INTO _campaign;
  SELECT NULLIF(JSON_VALUE(_args, "$.source"), '') INTO _source;
  SELECT NULLIF(JSON_VALUE(_args, "$.method"), '') INTO _method;
  SELECT JSON_VALUE(_args, "$.joined_from") INTO _raw_from;
  SELECT JSON_VALUE(_args, "$.joined_to") INTO _raw_to;

  -- Shape-gated as users_list gates its range: under STRICT_TRANS_TABLES a
  -- malformed bound assigned to a DATE raises rather than reading as absent.
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  CALL pageToLimits(_page, _offset, _range);
  SELECT
    _page AS `page`,
    COUNT(*) OVER () AS matches,
    t.uid,
    -- The stored address, falling back to the live one. The row keeps its own
    -- copy precisely so a deleted account still has a name against it.
    IFNULL(t.email, d.email) AS email,
    t.campaign,
    t.source,
    t.medium,
    t.content,
    t.ref,
    t.method,
    t.ctime,
    FROM_UNIXTIME(t.ctime, '%Y/%m/%d : %H:%i') AS date,
    -- 1 when the account is gone. The signup still happened.
    (d.id IS NULL) AS deleted
  FROM yp.signup_track t
  LEFT JOIN yp.drumate d ON d.id = t.uid
  WHERE IF(_campaign IS NULL, 1, t.campaign = _campaign)
    AND IF(_source IS NULL, 1, t.source = _source)
    AND IF(_method IS NULL, 1, t.method = _method)
    AND IF(_from IS NULL, 1, t.ctime >= UNIX_TIMESTAMP(_from))
    AND IF(_to IS NULL, 1, t.ctime < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY))
  ORDER BY
    CASE WHEN LCASE(_column) = 'date' AND LCASE(_order) = 'asc' THEN t.ctime END ASC,
    CASE WHEN LCASE(_column) = 'date' AND LCASE(_order) = 'desc' THEN t.ctime END DESC,
    CASE WHEN LCASE(_column) = 'campaign' AND LCASE(_order) = 'asc' THEN t.campaign END ASC,
    CASE WHEN LCASE(_column) = 'campaign' AND LCASE(_order) = 'desc' THEN t.campaign END DESC,
    -- Tie-break, so a page boundary is stable: ctime has one-second resolution
    -- and two signups in the same second could otherwise swap places between
    -- page 1 and page 2, showing one twice and hiding the other.
    t.uid DESC
  LIMIT _offset, _range;
END$

DELIMITER ;
