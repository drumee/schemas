DELIMITER $

-- =========================================================
-- mkt_grant_issue
-- Mint, or RE-mint, the one grant an address holds for a campaign.
--
-- INSERT ... ON DUPLICATE KEY UPDATE against uni_campaign_email, which is what
-- makes "one mail = one offer" structural: the first send creates the row, and
-- every later send -- a resend the recipient asked for, a re-run of the same
-- campaign, a double-clicked Send button on the dashboard -- rotates `token`
-- on that same row. There is no path here that produces a second grant for an
-- address, because the database will not accept one.
--
-- Rotating rather than reusing the token matters: the old link stops working
-- the moment a new one is sent, so a forwarded copy of the FIRST mail cannot
-- be redeemed after the recipient has asked for a replacement.
--
-- RE-ISSUE RESETS THE CLAIM. status goes back to 'issued', claim_count is
-- kept (it is the audit trail) but first_claim_at/last_claim_at stay put. That
-- is the entire point of a resend: the person spent their single use and is
-- being given another.
--
-- Refuses, rather than silently doing nothing:
--   CODE_NOT_FOUND     no such coupon
--   GRANT_REVOKED      an admin killed this one; a resend must not revive it
--   RESEND_LIMIT       _max_sends reached (send_count INCLUDES the first send)
--   RESEND_COOLDOWN    inside _cooldown_sec of the last send
--
-- The limits protect the INBOX and the SMTP relay (mail.drumee.com refuses
-- more than 50 concurrent connections per IP), not the discount budget --
-- unlimited resends still could not produce a second deal, because of the
-- unique key above and because mkt_coupon_redemption caps the address at one
-- live deal regardless.
--
-- @param _campaign     utm_campaign of the mail
-- @param _code         coupon code being granted
-- @param _email        recipient
-- @param _uid          payer uid when the caller knows it, else NULL/''
-- NULL AND 0 ARE DIFFERENT for the three limits: NULL takes the default, 0
-- disables the limit. Folding them together would make "no cooldown"
-- inexpressible, and a campaign re-run mails the same list twice inside a
-- second.
--
-- @param _ttl_sec      life of the link (NULL/<=0 -> 30 days)
-- @param _single_use   1 = spent by its first claim (NULL -> 1)
-- @param _max_sends    total sends allowed on this grant (NULL -> 3, 0 -> no limit)
-- @param _cooldown_sec minimum gap between sends (NULL -> 900, 0 -> none)
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_grant_issue`$
CREATE PROCEDURE `mkt_grant_issue`(
  IN _campaign     VARCHAR(64),
  IN _code         VARCHAR(64),
  IN _email        VARCHAR(255),
  IN _uid          VARCHAR(16),
  IN _ttl_sec      INT,
  IN _single_use   TINYINT,
  IN _max_sends    INT,
  IN _cooldown_sec INT
)
proc: BEGIN
  DECLARE _cid INT UNSIGNED;
  DECLARE _now INT UNSIGNED;
  DECLARE _norm VARCHAR(64);
  DECLARE _em VARCHAR(255);
  DECLARE _camp VARCHAR(64);
  DECLARE _token CHAR(32);
  DECLARE _id INT UNSIGNED;
  DECLARE _status VARCHAR(16);
  DECLARE _sends SMALLINT UNSIGNED;
  DECLARE _last INT UNSIGNED;

  SET _now = UNIX_TIMESTAMP();
  SET _norm = UPPER(TRIM(IFNULL(_code, '')));
  SET _em = LOWER(TRIM(IFNULL(_email, '')));
  SET _camp = TRIM(IFNULL(_campaign, ''));
  -- NULL means "use the default"; 0 means "no limit". Those are different
  -- answers and both are needed -- a campaign re-run mails the same list twice
  -- in a second and must not trip its own cooldown -- so 0 cannot be folded
  -- into the default the way NULL is. A negative or absurd _ttl_sec would
  -- issue a link that is already dead, so that one clamps instead.
  SET _ttl_sec = IF(IFNULL(_ttl_sec, 0) > 0, _ttl_sec, 2592000);
  SET _max_sends = IFNULL(_max_sends, 3);
  SET _cooldown_sec = IFNULL(_cooldown_sec, 900);
  SET _single_use = IFNULL(_single_use, 1);

  IF _camp = '' OR _norm = '' OR _em = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  SELECT id INTO _cid FROM mkt_coupon WHERE code = _norm LIMIT 1;
  IF _cid IS NULL THEN
    SELECT 'CODE_NOT_FOUND' AS error, _norm AS code;
    LEAVE proc;
  END IF;

  -- Existing grant for this address on this campaign?
  SELECT id, status, send_count, last_sent_at
    INTO _id, _status, _sends, _last
    FROM mkt_mail_grant
   WHERE campaign = _camp AND email = _em
   LIMIT 1;

  IF _id IS NOT NULL THEN
    IF _status = 'revoked' THEN
      SELECT 'GRANT_REVOKED' AS error, _em AS email;
      LEAVE proc;
    END IF;
    IF _max_sends > 0 AND _sends >= _max_sends THEN
      SELECT 'RESEND_LIMIT' AS error, _sends AS send_count,
             _max_sends AS max_sends;
      LEAVE proc;
    END IF;
    IF _cooldown_sec > 0
       AND _last IS NOT NULL AND (_now - _last) < _cooldown_sec THEN
      SELECT 'RESEND_COOLDOWN' AS error,
             (_cooldown_sec - (_now - _last)) AS retry_after;
      LEAVE proc;
    END IF;
  END IF;

  -- 32 hex. Not a cryptographic secret in the sense a password is: it lives
  -- 30 days, it is single-use, and an authenticated identity check stands
  -- behind it. UUID() alone would be guessable-adjacent (it embeds a clock and
  -- the MAC address), so it is mixed with RAND() and the address and hashed.
  SET _token = SUBSTRING(
    SHA2(CONCAT(UUID(), RAND(), _em, _camp, _now), 256), 1, 32);

  INSERT INTO mkt_mail_grant
    (campaign, coupon_id, code, email, uid, token, status, single_use,
     send_count, claim_count, issued_at, expires_at, last_sent_at, ctime, mtime)
  VALUES
    (_camp, _cid, _norm, _em, NULLIF(TRIM(IFNULL(_uid, '')), ''), _token,
     'issued', _single_use, 1, 0, _now, _now + _ttl_sec, _now, _now, _now)
  ON DUPLICATE KEY UPDATE
    -- The coupon may have changed between sends (a campaign re-pointed at a
    -- fresh code); the grant follows it.
    coupon_id   = _cid,
    code        = _norm,
    uid         = IFNULL(NULLIF(TRIM(IFNULL(_uid, '')), ''), uid),
    token       = _token,
    status      = 'issued',
    single_use  = _single_use,
    send_count  = send_count + 1,
    issued_at   = _now,
    expires_at  = _now + _ttl_sec,
    last_sent_at = _now,
    mtime       = _now;

  SELECT g.id, g.campaign, g.code, g.email, g.token, g.status, g.single_use,
         g.send_count, g.claim_count, g.expires_at
    FROM mkt_mail_grant g
   WHERE g.campaign = _camp AND g.email = _em
   LIMIT 1;
END $

DELIMITER ;
