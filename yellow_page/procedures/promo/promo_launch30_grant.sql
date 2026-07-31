DELIMITER $

-- =========================================================
-- promo_launch30_grant
-- Materialise the LAUNCH30 claim: a Team-plan yp.quota row for
-- (_domain_id, _org_id), source='promo-launch30', no card, no
-- Stripe object anywhere — exactly the design doc's "NO Stripe
-- customer, NO payment method, NO subscription object. Nothing
-- to charge." Plus the promo_launch30 bookkeeping row that
-- records who claimed, when, and when it lapses.
--
-- Called AFTER org_provision (Node orchestrates: bootstrap the
-- org/domain first, then this). Idempotent on _payer_id: a
-- second call once already claimed/expired is a no-op that just
-- returns the existing row — this is what makes a retried claim
-- (org_provision succeeded, this call failed) self-healing
-- without double-granting or resetting the trial clock.
--
-- period_end mirrors payment_apply_entitlement's shape so
-- get_quota's org branch (CASE 1, domain_id > 1) picks this row
-- up exactly the same way it picks up a Stripe org row — no
-- reader changes needed. Expiry itself is ACTIVE, not read-time
-- (that branch has no source/period_end filter at all — see
-- get_quota.sql — because Stripe expiry is handled the same
-- way): promo_launch30_due + payment_clear_entitlement on the
-- worker side deletes this row when trial_ends_at passes, which
-- drops the org member back to their own per-user tier exactly
-- like a cancelled Stripe org subscription does.
-- =========================================================
DROP PROCEDURE IF EXISTS `promo_launch30_grant`$
CREATE PROCEDURE `promo_launch30_grant`(
  IN _payer_id   VARCHAR(16),
  IN _org_id     VARCHAR(16),
  IN _domain_id  INT,
  IN _trial_days INT
)
proc: BEGIN
  DECLARE _plan_quota JSON;
  DECLARE _period_end INT UNSIGNED;
  DECLARE _already INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT COUNT(*) INTO _already
  FROM promo_launch30
  WHERE payer_id = _payer_id AND status IN ('claimed', 'expired');

  IF _already > 0 THEN
    SELECT status, org_id, domain_id, claimed_at, trial_ends_at, expired_at
    FROM promo_launch30 WHERE payer_id = _payer_id LIMIT 1;
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Caller (service/private/promo.js) reads PROMO_LAUNCH30_TRIAL_DAYS with a
  -- 30-day default; IFNULL/0 guard here is defense-in-depth against a caller
  -- that forgets the argument, not the source of truth for the length.
  SET _period_end = UNIX_TIMESTAMP() + (IFNULL(NULLIF(_trial_days, 0), 30) * 86400);

  SELECT quota FROM yp.plan
    WHERE plan_code = 'team' AND entity_type = 'org' AND active = 1
    LIMIT 1
  INTO _plan_quota;
  -- Catalog missing/deactivated: the Team defaults from the design doc
  -- (100 GB, 10 seats) are the failure-safe floor, same rationale as
  -- reward_grant_storage's IFNULL fallback.
  SET _plan_quota = IFNULL(_plan_quota,
    JSON_OBJECT('plan', 'team', 'disk', 100000000000, 'seat', 10));
  SET _plan_quota = JSON_SET(_plan_quota, '$.plan', 'team', '$.organization', 1);

  INSERT INTO yp.quota
    (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
  VALUES
    (_domain_id, _org_id, 'team', _plan_quota, 'promo-launch30', _period_end,
     UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    plan = 'team', quota = VALUES(quota), source = 'promo-launch30',
    period_end = _period_end, mtime = UNIX_TIMESTAMP();

  INSERT INTO promo_launch30
    (payer_id, status, org_id, domain_id, claimed_at, trial_ends_at, ctime, mtime)
  VALUES
    (_payer_id, 'claimed', _org_id, _domain_id, UNIX_TIMESTAMP(), _period_end,
     UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    status = 'claimed', org_id = _org_id, domain_id = _domain_id,
    claimed_at = UNIX_TIMESTAMP(), trial_ends_at = _period_end,
    mtime = UNIX_TIMESTAMP();

  COMMIT;

  SELECT status, org_id, domain_id, claimed_at, trial_ends_at, expired_at
  FROM promo_launch30 WHERE payer_id = _payer_id LIMIT 1;
END $

DELIMITER ;
