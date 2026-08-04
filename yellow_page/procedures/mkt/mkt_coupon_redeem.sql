DELIMITER $

-- =========================================================
-- mkt_coupon_redeem
-- Redeem a FREE-PERIOD coupon straight into an entitlement — no Stripe
-- Checkout, no card, no subscription object. Same shape as the LAUNCH30
-- claim (promo_launch30_grant): a yp.quota row the expiry worker later
-- deletes, which is exactly what an org's Stripe cancellation produces.
--
-- Only codes with percent_off = 0 AND trial_days > 0 may come through
-- here. A percent-off code discounts a PAID subscription — there is money
-- to collect, so it belongs at checkout; granting it free here would give
-- the plan away. The caller checks this too, but the rule is enforced
-- where it cannot be bypassed.
--
-- _plan is the plan the caller CHOSE (the coupon says where a code may be
-- spent via plan_scope, never which plan to hand out). plan_scope still
-- constrains it, so a Team-only code cannot be redeemed for Business.
--
-- Idempotent per email: an existing live redemption is returned as-is
-- rather than granting twice.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_redeem`$
CREATE PROCEDURE `mkt_coupon_redeem`(
  IN _code      VARCHAR(64),
  IN _email     VARCHAR(255),
  IN _uid       VARCHAR(16),
  IN _plan      VARCHAR(32),
  IN _org_id    VARCHAR(16),
  IN _domain_id INT,
  IN _ttl_sec   INT
)
proc: BEGIN
  DECLARE _cid INT UNSIGNED;
  DECLARE _partner VARCHAR(128);
  DECLARE _active TINYINT;
  DECLARE _ends_at INT UNSIGNED;
  DECLARE _max INT UNSIGNED;
  DECLARE _used INT UNSIGNED;
  DECLARE _scope VARCHAR(32);
  DECLARE _pct INT;
  DECLARE _trial INT;
  DECLARE _months INT;
  DECLARE _kind VARCHAR(32);
  DECLARE _now INT UNSIGNED;
  DECLARE _norm VARCHAR(64);
  DECLARE _em VARCHAR(255);
  DECLARE _pl VARCHAR(32);
  DECLARE _stale_before INT UNSIGNED;
  DECLARE _live_id INT UNSIGNED;
  DECLARE _period_end INT UNSIGNED;
  DECLARE _plan_quota JSON;
  -- Resolved from the catalog, never assumed: 'org' for team/business,
  -- 'user' for a personal plan like pro. Decides who HOLDS the quota row.
  DECLARE _etype VARCHAR(8);
  DECLARE _hold_payer VARCHAR(16);
  DECLARE _hold_domain INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET _now = UNIX_TIMESTAMP();
  SET _norm = UPPER(TRIM(_code));
  SET _em = LOWER(TRIM(IFNULL(_email, '')));
  SET _pl = LOWER(TRIM(IFNULL(_plan, '')));
  SET _ttl_sec = IFNULL(NULLIF(_ttl_sec, 0), 86400);
  SET _stale_before = _now - _ttl_sec;

  -- _org_id is NOT required here: a personal plan (pro) has no organisation
  -- and the caller passes ''. Whether an org is actually needed depends on
  -- the plan's entity_type, which is only known after the catalog lookup —
  -- so that requirement is enforced there (ORG_REQUIRED), not up front.
  IF _norm = '' OR _em = '' OR _pl = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  SELECT id, partner, active, ends_at, max_redemptions, plan_scope,
         percent_off, trial_days, duration_months, kind
    INTO _cid, _partner, _active, _ends_at, _max, _scope,
         _pct, _trial, _months, _kind
    FROM mkt_coupon WHERE code = _norm LIMIT 1;

  IF _cid IS NULL THEN
    SELECT 'CODE_NOT_FOUND' AS error, _norm AS code;
    LEAVE proc;
  END IF;
  IF IFNULL(_active, 0) <> 1 THEN
    SELECT 'CODE_INACTIVE' AS error, _norm AS code;
    LEAVE proc;
  END IF;
  IF _ends_at IS NOT NULL AND _ends_at > 0 AND _ends_at < _now THEN
    SELECT 'CODE_EXPIRED' AS error, _norm AS code, _ends_at AS ends_at;
    LEAVE proc;
  END IF;

  SET _scope = LOWER(NULLIF(TRIM(IFNULL(_scope, '')), ''));
  IF _scope IS NOT NULL AND _scope <> 'all' AND _scope <> _pl THEN
    SELECT 'COUPON_PLAN_MISMATCH' AS error, _norm AS code,
           _scope AS plan_scope, _pl AS requested_plan;
    LEAVE proc;
  END IF;

  -- The free-period rule. A discount code cannot be turned into a gift.
  IF IFNULL(_pct, 0) <> 0 OR IFNULL(_trial, 0) <= 0 THEN
    SELECT 'COUPON_NOT_REDEEMABLE' AS error, _norm AS code,
           _kind AS kind, _pct AS percent_off, _trial AS trial_days;
    LEAVE proc;
  END IF;

  -- Already holding a live deal? Return it instead of granting twice.
  SELECT id INTO _live_id
    FROM mkt_coupon_redemption
   WHERE email = _em
     AND (status = 'confirmed'
          OR (status = 'pending' AND reserved_at >= _stale_before))
   ORDER BY FIELD(status, 'confirmed', 'pending'), id DESC
   LIMIT 1;

  IF _live_id IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM mkt_coupon_redemption
                WHERE id = _live_id AND code = _norm AND status = 'confirmed') THEN
      SELECT r.*, 1 AS already FROM mkt_coupon_redemption r WHERE r.id = _live_id;
      LEAVE proc;
    END IF;
    SELECT 'EMAIL_ALREADY_USED' AS error, _em AS email;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _used FROM mkt_coupon_redemption
   WHERE coupon_id = _cid
     AND (status = 'confirmed'
          OR (status = 'pending' AND reserved_at >= _stale_before));
  IF _max IS NOT NULL AND _max > 0 AND _used >= _max THEN
    SELECT 'CODE_EXHAUSTED' AS error, _norm AS code,
           _used AS used_count, _max AS max_redemptions;
    LEAVE proc;
  END IF;

  START TRANSACTION;

  SET _period_end = _now + (_trial * 86400);

  -- Entitlement figures come from the catalog for the CHOSEN plan, so a
  -- Business redemption grants Business quota, not a hardcoded Team one.
  --
  -- entity_type is READ from the catalog rather than assumed 'org'. Pro
  -- (2026-08-03) is a personal plan — entity_type 'user', organization 0 —
  -- and forcing the org shape on it would key the quota row to an
  -- organisation the redeemer must not be given, and stamp organization:1
  -- on a plan that sells none.
  SELECT quota, entity_type INTO _plan_quota, _etype FROM yp.plan
    WHERE plan_code = _pl AND active = 1 AND entity_type IN ('org', 'user')
    ORDER BY FIELD(entity_type, 'org', 'user')
    LIMIT 1;
  IF _plan_quota IS NULL THEN
    ROLLBACK;
    SELECT 'PLAN_NOT_SELLABLE' AS error, _pl AS plan;
    LEAVE proc;
  END IF;

  IF _etype = 'org' THEN
    -- Org plan: the organisation holds the entitlement, and every member
    -- reads it through the tenant-first cascade in get_quota.
    IF _org_id IS NULL OR _org_id = '' THEN
      ROLLBACK;
      SELECT 'ORG_REQUIRED' AS error, _pl AS plan;
      LEAVE proc;
    END IF;
    SET _plan_quota = JSON_SET(_plan_quota, '$.plan', _pl, '$.organization', 1);
    SET _hold_payer = _org_id;
    SET _hold_domain = _domain_id;
  ELSE
    -- Personal plan: the PAYER holds it, on whatever domain they already
    -- live on. No organisation is created or required — mirrors the
    -- individual branch of payment_apply_entitlement, so a Pro granted by
    -- coupon and a Pro bought through Stripe produce the same row.
    SET _plan_quota = JSON_SET(_plan_quota, '$.plan', _pl);
    SET _hold_payer = _uid;
    SELECT domain_id INTO _hold_domain FROM yp.drumate WHERE id = _uid LIMIT 1;
    SET _hold_domain = IFNULL(_hold_domain, 1);
  END IF;

  -- source names the campaign so a support question ("why is this org on
  -- Team?") is answerable from the quota row alone.
  INSERT INTO yp.quota
    (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
  VALUES
    (_hold_domain, _hold_payer, _pl, _plan_quota, 'mkt-coupon', _period_end, _now, _now)
  ON DUPLICATE KEY UPDATE
    plan = _pl, quota = VALUES(quota), source = 'mkt-coupon',
    period_end = _period_end, mtime = _now;

  -- org_id carries the ENTITLEMENT HOLDER, not strictly an organisation: the
  -- org id for a team/business grant, the uid for a personal one. The expiry
  -- worker feeds this column straight to payment_clear_entitlement, which
  -- keys on payer_id and already has an individual branch (it re-materialises
  -- a claim-reward row when the id belongs to a drumate). Keeping one column
  -- means the revoke path needs no branch of its own.
  INSERT INTO mkt_coupon_redemption
    (coupon_id, code, partner, email, uid, plan, period, entity_type,
     status, reserved_at, confirmed_at, trial_ends_at, org_id, domain_id,
     ctime, mtime)
  VALUES
    (_cid, _norm, IFNULL(_partner, ''), _em, _uid, _pl, 'trial', _etype,
     'confirmed', _now, _now, _period_end, _hold_payer, _hold_domain, _now, _now);

  COMMIT;

  SELECT r.*, 0 AS already FROM mkt_coupon_redemption r
   WHERE r.id = LAST_INSERT_ID();
END $

DELIMITER ;
