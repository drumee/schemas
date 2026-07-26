DELIMITER $

-- =========================================================
-- users_list
--
-- NOTE: this file was regenerated from the DEPLOYED procedure. The previous
-- revision in git had drifted badly out of date — it selected none of
-- uid/date/plan/source/referred_by/last_login, had no pagelength, matched the
-- domain with `=` instead of LIKE, and defaulted _type/_domain to the STRING
-- 'desc' (IFNULL(..., 'desc')), which would have filtered every row away.
-- Applying that revision would have blanked the analytics users table.
--
-- Filters (all optional, all matched with a substring LIKE):
--   domain  — the part of the address after the @
--   email   — the whole address
--   type    — "gmail" / anything else, partitions on gmail.com
-- =========================================================
DROP PROCEDURE IF EXISTS `users_list`$
CREATE PROCEDURE `users_list`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _column VARCHAR(20) DEFAULT 'name';
  DECLARE _order VARCHAR(20) DEFAULT 'asc';
  DECLARE _type VARCHAR(20) DEFAULT NULL;
  DECLARE _domain VARCHAR(20) DEFAULT NULL;
  DECLARE _email VARCHAR(128) DEFAULT NULL;
  DECLARE _page INTEGER DEFAULT 1;

  SELECT IFNULL(JSON_VALUE(_args, "$.column"), 'date') INTO _column;
  SELECT IFNULL(JSON_VALUE(_args, "$.order"), 'desc') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pagelength"), 45) INTO @rows_per_page;
  -- No IFNULL default here on purpose: these are filters, and an absent key
  -- has to stay NULL so the IF() below falls through to "match everything".
  SELECT JSON_VALUE(_args, "$.type") INTO _type;
  SELECT JSON_VALUE(_args, "$.domain") INTO _domain;
  SELECT JSON_VALUE(_args, "$.email") INTO _email;

  CALL pageToLimits(_page, _offset, _range);
  SELECT
    _page as `page`,
    d.id uid,
    e.ctime,
    d.firstname,
    d.lastname,
    FROM_UNIXTIME(e.ctime, '%Y/%m/%d : %H:%i') date,
    SUBSTRING_INDEX(d.email, '@', 1) AS username,
    SUBSTRING_INDEX(d.email, '@', -1) AS domain,
    IFNULL(JSON_VALUE(d.profile, '$.category'), 'free') AS plan,
    IF(EXISTS(SELECT 1 FROM emailing em WHERE em.email = d.email), 'Email', 'Direct') AS source,
    LOWER(JSON_VALUE(d.profile, '$.ref')) AS referred_by,
    email,
    FROM_UNIXTIME(ll.last_login, '%Y/%m/%d : %H:%i') AS last_login
  FROM yp.entity e
    INNER JOIN (yp.drumate d) USING(id)
    LEFT JOIN (
      SELECT uid, MAX(ctime) AS last_login
      FROM yp.services_log
      WHERE JSON_VALUE(args, '$.success') = '1'
      GROUP BY uid
    ) ll ON ll.uid = d.id
    -- HAVING, not WHERE: `domain` and `email` here are the SELECT aliases
    -- above, which WHERE cannot see.
    HAVING
    IF(_type IS NULL, 1, IF(_type="gmail", domain="gmail.com", domain!="gmail.com")) AND
    IF(_domain IS NULL, 1, domain LIKE CONCAT("%", _domain, "%")) AND
    IF(_email IS NULL, 1, email LIKE CONCAT("%", _email, "%"))
    ORDER BY
      CASE WHEN LCASE(_column) = 'date' AND LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_column) = 'date' AND LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_column) = 'email' AND LCASE(_order) = 'asc' THEN email END ASC,
      CASE WHEN LCASE(_column) = 'email' AND LCASE(_order) = 'desc' THEN email END DESC,
      CASE WHEN LCASE(_column) = 'username' AND LCASE(_order) = 'asc' THEN username END ASC,
      CASE WHEN LCASE(_column) = 'username' AND LCASE(_order) = 'desc' THEN username END DESC,
      CASE WHEN LCASE(_column) = 'domain' AND LCASE(_order) = 'asc' THEN domain END ASC,
      CASE WHEN LCASE(_column) = 'domain' AND LCASE(_order) = 'desc' THEN domain END DESC,
      CASE WHEN LCASE(_column) = 'last_login' AND LCASE(_order) = 'asc' THEN ll.last_login END ASC,
      CASE WHEN LCASE(_column) = 'last_login' AND LCASE(_order) = 'desc' THEN ll.last_login END DESC
    LIMIT _offset, _range;
END$

DELIMITER ;
