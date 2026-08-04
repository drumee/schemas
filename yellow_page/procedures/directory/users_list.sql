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
    -- LOGOUT IS NOT A LOGIN, and args.success alone cannot tell them apart.
    -- session.logout() calls the same _log_connection the sign-in paths do,
    -- passing no `success` of its own, and _log_connection spreads its argument
    -- over a `{ success: 1, ... }` default -- so a logout is written with
    -- success='1' exactly like an accepted sign-in, and MAX(ctime) returns it.
    -- The column meant "last successful session EVENT", and the error only ever
    -- ran one way: it reported users as more recently active than they were. On
    -- stage this overstated 111 users, on average by ~62 hours and at worst by
    -- 227 days.
    --
    -- Excluded by name, not by an allow-list of login names, because `name` is
    -- whatever service string the client posted -- yp.signin (the alias the
    -- sign-in form actually calls), yp.login, yp.login_top, google.callback,
    -- apple.callback -- and those are spread across repos, so an allow-list
    -- would silently drop whichever one nobody remembered. Naming the single
    -- event that is not a login cannot.
    --
    -- MATCH THE SUBSTRING, not the literal 'yp.logout': the event is recorded
    -- under the service that was called, and stage's rows say `drumate.logout`.
    -- An equality test on 'yp.logout' would have fixed nothing at all.
    --
    -- NULL name is KEPT: it means the service string was missing, not that the
    -- event was a logout, and success='1' only ever comes from _log_connection.
    --
    -- yp.show_login_log already reads this column this way, treating 'yp.login'
    -- as in and 'yp.logout' as out.
    LEFT JOIN (
      SELECT uid, MAX(ctime) AS last_login
      FROM yp.services_log
      WHERE JSON_VALUE(args, '$.success') = '1'
        AND (`name` IS NULL OR `name` NOT LIKE '%logout%')
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
