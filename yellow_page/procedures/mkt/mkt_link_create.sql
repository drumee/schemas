DELIMITER $

-- =========================================================
-- mkt_link_create
--
-- The ONLY writer of yp.mkt_campaign_link.
--
-- IT REFUSES; IT REPAIRS ONLY CASE. The builder in analytics-ui normalizes as
-- the user types — lowercasing, trimming, folding accents, replacing spaces —
-- and shows what it changed. By the time a value reaches here it is either
-- already normalized or it arrived from somewhere that is not the builder.
-- Folding accents a second time in SQL would mean two normalizers, in two
-- languages, that have to agree forever; the first character they disagree on
-- is a campaign with two rows. LOWER is the exception, and only because
-- LOWER() and JS .toLowerCase() cannot disagree on ASCII: 'LinkedIn' is stored
-- as 'linkedin'. Everything else outside the charset is rejected — 'Été',
-- 'two words' and 'news@letter' all come back SOURCE_INVALID.
--
-- The duplicate guard is the UNIQUE key, not a SELECT. Two admins saving the
-- same link in the same second both pass a SELECT and both insert; only the
-- index can refuse the second one. The handler below turns 1062 into a report.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_link_create`$
CREATE PROCEDURE `mkt_link_create`(
  IN _name        VARCHAR(160),
  IN _destination VARCHAR(512),
  IN _source      VARCHAR(64),
  IN _medium      VARCHAR(64),
  IN _campaign    VARCHAR(64),
  IN _term        VARCHAR(64),
  IN _content     VARCHAR(64),
  IN _ref         VARCHAR(64),
  IN _owner       VARCHAR(64),
  IN _created_by  VARCHAR(16)
)
BEGIN
  DECLARE _s   VARCHAR(64);
  DECLARE _m   VARCHAR(64);
  DECLARE _c   VARCHAR(64);
  DECLARE _t   VARCHAR(64);
  DECLARE _ct  VARCHAR(64);
  DECLARE _r   VARCHAR(64);
  DECLARE _now INT UNSIGNED;
  DECLARE _dup TINYINT DEFAULT 0;
  -- CONTINUE, not EXIT: the body has to carry on to the report below.
  DECLARE CONTINUE HANDLER FOR 1062 SET _dup = 1;

  SET _now  = UNIX_TIMESTAMP();
  SET _name = TRIM(IFNULL(_name, ''));
  SET _s    = LOWER(TRIM(IFNULL(_source, '')));
  SET _m    = LOWER(TRIM(IFNULL(_medium, '')));
  SET _c    = LOWER(TRIM(IFNULL(_campaign, '')));
  SET _t    = LOWER(TRIM(IFNULL(_term, '')));
  SET _ct   = LOWER(TRIM(IFNULL(_content, '')));
  SET _r    = LOWER(TRIM(IFNULL(_ref, '')));
  SET _destination = TRIM(IFNULL(_destination, ''));

  IF _name = '' THEN
    SELECT 'NAME_REQUIRED' AS error;

  -- Allowlist, anchored. A bare LIKE '%drumee.com%' would accept
  -- https://drumee.com.evil.tld/ — the host has to END there.
  ELSEIF _destination NOT REGEXP '^https://(www[.]|get[.])?drumee[.]com(/|$)' THEN
    SELECT 'DESTINATION_INVALID' AS error, _destination AS destination;

  ELSEIF _s = '' OR _s NOT REGEXP '^[a-z0-9._-]{1,64}$' THEN
    SELECT 'SOURCE_INVALID' AS error, _s AS value;

  -- Closed vocabulary. The channel table GROUPS BY medium, so this is the one
  -- column that cannot be allowed to drift; 'social' is absent on purpose —
  -- paid and organic social behave nothing alike.
  ELSEIF _m NOT IN ('cpc','paid-social','organic-social','email','referral',
                    'affiliate','display','print','qr','community','pr') THEN
    SELECT 'MEDIUM_INVALID' AS error, _m AS value;

  ELSEIF _c REGEXP '(^|-)test(-|$)' THEN
    SELECT 'CAMPAIGN_RESERVED' AS error, _c AS value;

  ELSEIF _c NOT REGEXP '^[0-9]{6}-[a-z]{2}-[a-z0-9-]{2,40}$' THEN
    SELECT 'CAMPAIGN_INVALID' AS error, _c AS value;

  ELSEIF _t <> '' AND _t NOT REGEXP '^[a-z0-9._-]{1,64}$' THEN
    SELECT 'TERM_INVALID' AS error, _t AS value;

  ELSEIF _ct <> '' AND _ct NOT REGEXP '^[a-z0-9._-]{1,64}$' THEN
    SELECT 'CONTENT_INVALID' AS error, _ct AS value;

  ELSEIF _r <> '' AND _r NOT REGEXP '^[a-z0-9._-]{1,64}$' THEN
    SELECT 'REF_INVALID' AS error, _r AS value;

  ELSE
    INSERT INTO mkt_campaign_link
      (name, destination, utm_source, utm_medium, utm_campaign, utm_term,
       utm_content, ref, owner, created_by, archived, ctime, mtime)
    VALUES
      (_name, _destination, _s, _m, _c, _t, _ct, _r,
       TRIM(IFNULL(_owner, '')), _created_by, 0, _now, _now);

    IF _dup = 1 THEN
      -- Name the link that already holds the tuple. "This already exists" with
      -- no way to find it sends the reader hunting through the registry.
      SELECT 'LINK_DUPLICATE' AS error, id, name, owner,
             FROM_UNIXTIME(ctime, '%Y-%m-%d') AS created
        FROM mkt_campaign_link
       WHERE utm_source = _s AND utm_medium = _m AND utm_campaign = _c
         AND utm_term = _t AND utm_content = _ct
       LIMIT 1;
    ELSE
      SELECT * FROM mkt_campaign_link WHERE id = LAST_INSERT_ID();
    END IF;
  END IF;
END $

DELIMITER ;
