DELIMITER $

-- =========================================================
-- mkt_coupon_create
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_create`$
CREATE PROCEDURE `mkt_coupon_create`(
  IN _code             VARCHAR(64),
  IN _partner          VARCHAR(128),
  IN _kind             VARCHAR(32),
  IN _percent_off      INT,
  IN _duration_months  INT,
  IN _trial_days       INT,
  IN _ends_at          INT,
  IN _max_redemptions  INT,
  IN _notes            VARCHAR(512),
  IN _created_by       VARCHAR(16),
  IN _plan_scope       VARCHAR(32)
)
BEGIN
  DECLARE _norm VARCHAR(64);
  DECLARE _now INT UNSIGNED;
  SET _now = UNIX_TIMESTAMP();
  SET _norm = UPPER(TRIM(_code));
  SET _kind = IFNULL(NULLIF(TRIM(_kind), ''), 'kol_discount');
  SET _partner = IFNULL(TRIM(_partner), '');
  -- Empty/omitted → 'all', so an older caller that does not know about the
  -- argument still creates a coupon with today's behaviour.
  SET _plan_scope = LOWER(IFNULL(NULLIF(TRIM(_plan_scope), ''), 'all'));

  -- Kind-aware defaults:
  --   kol_discount  = trial_days free + percent_off for duration_months
  --   percent_off   = % discount only (no free period)
  --   warm_trial / free_months = N months free (trial), no % discount
  IF _kind IN ('warm_trial', 'free_months') THEN
    SET _percent_off = IFNULL(_percent_off, 0);
    SET _duration_months = IFNULL(NULLIF(_duration_months, 0), 2);
    SET _trial_days = IFNULL(NULLIF(_trial_days, 0), _duration_months * 30);
  ELSEIF _kind = 'percent_off' THEN
    SET _percent_off = IFNULL(NULLIF(_percent_off, 0), 50);
    -- NULL → default 3 cycles; explicit 0 = Stripe duration 'once'
    SET _duration_months = IF(_duration_months IS NULL, 3, _duration_months);
    SET _trial_days = IFNULL(_trial_days, 0);
  ELSE
    SET _percent_off = IFNULL(NULLIF(_percent_off, 0), 50);
    SET _duration_months = IFNULL(NULLIF(_duration_months, 0), 3);
    SET _trial_days = IFNULL(_trial_days, 30);
  END IF;

  IF _norm IS NULL OR _norm = '' OR CHAR_LENGTH(_norm) < 3 THEN
    SELECT 'CODE_INVALID' AS error;
  ELSEIF _percent_off = 0 AND IFNULL(_trial_days, 0) = 0 THEN
    SELECT 'OFFER_INVALID' AS error;
  -- Reject a scope that names a plan the catalog does not sell: a typo'd
  -- 'teams' would otherwise create a coupon that can never be redeemed and
  -- only surfaces as a mismatch at someone's checkout.
  ELSEIF _plan_scope <> 'all'
     AND NOT EXISTS (SELECT 1 FROM yp.plan WHERE plan_code = _plan_scope) THEN
    SELECT 'PLAN_SCOPE_INVALID' AS error, _plan_scope AS plan_scope;
  ELSEIF EXISTS (SELECT 1 FROM mkt_coupon WHERE code = _norm) THEN
    SELECT 'CODE_EXISTS' AS error, _norm AS code;
  ELSE
    INSERT INTO mkt_coupon
      (code, partner, kind, plan_scope, percent_off, duration_months, trial_days,
       active, ends_at, max_redemptions, notes, created_by, ctime, mtime)
    VALUES
      (_norm, _partner, _kind, _plan_scope, _percent_off, _duration_months, _trial_days,
       1, NULLIF(_ends_at, 0), NULLIF(_max_redemptions, 0), _notes, _created_by, _now, _now);
    SELECT * FROM mkt_coupon WHERE id = LAST_INSERT_ID();
  END IF;
END $

DELIMITER ;
