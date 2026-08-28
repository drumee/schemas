DELIMITER $

-- =========================================================
-- mkt_grant_claim
-- Exchange a mailed token for the coupon it grants -- the only place the code
-- is ever revealed.
--
-- THE LINK IS WORTH NOTHING WITHOUT THIS CALL. That is the whole design: the
-- mail carries `g=<32 hex>` and no code, so a forwarded copy hands the reader
-- a token that this procedure refuses. Compare the previous scheme, where the
-- code travelled in cleartext and the recipient check ran in the browser.
--
-- _email IS THE IDENTITY, NOT _uid. The caller reads it from
-- payment_get_payer(uid) -- the same source mkt_coupon_reserve and
-- preview_coupon key on -- so the three cannot disagree about who is buying.
-- _uid is recorded, and backfilled onto the row when the issue-time sender did
-- not know it, but it is never what the grant is matched against: the grant
-- was addressed to an inbox.
--
-- ONE CALL, ONE OUTCOME. This is not a "check" a caller can run and then
-- ignore -- a successful claim SPENDS a single-use grant. Callers that only
-- want to know whether an offer exists must not call this.
--
-- Refusals, all of them terminal for this token:
--   OFFER_NOT_FOUND    no such token (or it was rotated by a resend)
--   OFFER_EXPIRED      past expires_at
--   OFFER_REVOKED      an admin killed it
--   OFFER_NOT_YOURS    addressed to somebody else
--   OFFER_SPENT        single_use and already claimed
--   CODE_INACTIVE      the coupon behind it was switched off
--   CODE_EXPIRED       the coupon behind it is past ends_at
--
-- The last two are checked BEFORE the grant is marked, so a dead coupon does
-- not silently burn somebody's one run at it.
--
-- OFFER_NOT_YOURS DELIBERATELY DOES NOT SAY WHOSE. The caller is, by
-- definition, not the addressee; telling them which address the offer went to
-- would turn a stolen link into an address-disclosure oracle. It answers only
-- that this is not theirs.
--
-- OFFER_SPENT IS THE CAMPAIGN'S OWN REQUIREMENT, not a safety margin: click
-- the CTA, sign in, billing opens; sign out, click the same CTA, sign in
-- again, nothing happens. The way back is a resend (mkt_grant_resend), which
-- is why the refusal is named rather than folded into OFFER_NOT_FOUND -- the
-- UI has to be able to offer that button.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_grant_claim`$
CREATE PROCEDURE `mkt_grant_claim`(
  IN _token VARCHAR(64),
  IN _email VARCHAR(255),
  IN _uid   VARCHAR(16)
)
proc: BEGIN
  DECLARE _id INT UNSIGNED;
  DECLARE _gemail VARCHAR(255);
  DECLARE _status VARCHAR(16);
  DECLARE _single TINYINT;
  DECLARE _expires INT UNSIGNED;
  DECLARE _now INT UNSIGNED;
  DECLARE _tok VARCHAR(64);
  DECLARE _em VARCHAR(255);
  DECLARE _cactive TINYINT;
  DECLARE _cends INT UNSIGNED;

  SET _now = UNIX_TIMESTAMP();
  SET _tok = LOWER(TRIM(IFNULL(_token, '')));
  SET _em = LOWER(TRIM(IFNULL(_email, '')));

  IF _tok = '' OR _em = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  SELECT g.id, g.email, g.status, g.single_use, g.expires_at, c.active, c.ends_at
    INTO _id, _gemail, _status, _single, _expires, _cactive, _cends
    FROM mkt_mail_grant g
    LEFT JOIN mkt_coupon c ON c.id = g.coupon_id
   WHERE g.token = _tok
   LIMIT 1;

  IF _id IS NULL THEN
    SELECT 'OFFER_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;
  IF _status = 'revoked' THEN
    SELECT 'OFFER_REVOKED' AS error;
    LEAVE proc;
  END IF;

  -- Ownership BEFORE expiry, so a stranger holding a forwarded link learns
  -- only that it is not theirs -- never that it was valid and has aged out,
  -- which would confirm the address behind it was a real recipient.
  IF _gemail <> _em THEN
    SELECT 'OFFER_NOT_YOURS' AS error;
    LEAVE proc;
  END IF;

  IF _expires IS NOT NULL AND _expires > 0 AND _expires < _now THEN
    SELECT 'OFFER_EXPIRED' AS error, _expires AS expires_at;
    LEAVE proc;
  END IF;

  IF _single = 1 AND _status = 'claimed' THEN
    SELECT 'OFFER_SPENT' AS error;
    LEAVE proc;
  END IF;

  -- THE COUPON ITSELF MUST STILL BE USABLE, checked before the grant is
  -- marked. A single-use grant spent on a deactivated or expired code is gone
  -- for nothing: the holder gets an error, their one run is used up, and the
  -- only way back is a resend they have no reason to think they need. Refusing
  -- here leaves the grant untouched, so fixing the coupon fixes the link.
  IF IFNULL(_cactive, 0) <> 1 THEN
    SELECT 'CODE_INACTIVE' AS error;
    LEAVE proc;
  END IF;
  IF _cends IS NOT NULL AND _cends > 0 AND _cends < _now THEN
    SELECT 'CODE_EXPIRED' AS error, _cends AS ends_at;
    LEAVE proc;
  END IF;

  UPDATE mkt_mail_grant
     SET status = 'claimed',
         uid = IFNULL(NULLIF(TRIM(IFNULL(_uid, '')), ''), uid),
         claim_count = claim_count + 1,
         first_claim_at = IFNULL(first_claim_at, _now),
         last_claim_at = _now,
         mtime = _now
   WHERE id = _id;

  -- The coupon's own shape travels back, so the caller can price the offer
  -- without a second round trip and without ever having been told the code in
  -- advance.
  SELECT g.id AS grant_id, g.campaign, g.code, g.email, g.single_use,
         g.claim_count, g.expires_at,
         c.partner, c.kind, c.plan_scope, c.percent_off,
         c.duration_months, c.trial_days, c.active, c.ends_at
    FROM mkt_mail_grant g
    INNER JOIN mkt_coupon c ON c.id = g.coupon_id
   WHERE g.id = _id;
END $

DELIMITER ;
