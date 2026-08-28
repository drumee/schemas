DELIMITER $

-- =========================================================
-- mkt_coupon_reserve
-- Hold a pending redemption before Stripe Checkout. Anti-cheat:
--   - code must be active and not past ends_at
--   - email must not already have pending|confirmed (1 email = 1 live deal)
--   - max_redemptions (pending+confirmed) not exceeded
-- Stale pending (> _ttl_sec, default 24h) are released globally first.
-- Fresh pending for this email are NOT cleared (prevents code-hopping).
-- Re-reserve of the SAME code while still pending is idempotent.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_reserve`$
CREATE PROCEDURE `mkt_coupon_reserve`(
  IN _code      VARCHAR(64),
  IN _email     VARCHAR(255),
  IN _uid       VARCHAR(16),
  IN _plan      VARCHAR(32),
  IN _period    VARCHAR(16),
  IN _entity_type VARCHAR(16),
  IN _session_id VARCHAR(128),
  IN _ttl_sec   INT
)
proc: BEGIN
  DECLARE _cid INT UNSIGNED;
  DECLARE _partner VARCHAR(128);
  DECLARE _active TINYINT;
  DECLARE _ends_at INT UNSIGNED;
  DECLARE _max INT UNSIGNED;
  DECLARE _scope VARCHAR(32);
  DECLARE _used INT UNSIGNED;
  DECLARE _now INT UNSIGNED;
  DECLARE _norm VARCHAR(64);
  DECLARE _em VARCHAR(255);
  DECLARE _existing_id INT UNSIGNED;

  SET _now = UNIX_TIMESTAMP();
  SET _norm = UPPER(TRIM(_code));
  SET _em = LOWER(TRIM(_email));
  SET _ttl_sec = IFNULL(NULLIF(_ttl_sec, 0), 86400);

  IF _norm IS NULL OR _norm = '' OR _em IS NULL OR _em = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  -- Release abandoned holds by TTL only. Never clear a fresh pending for
  -- this email here — that would let one address hop partner codes.
  UPDATE mkt_coupon_redemption
     SET status = 'released', mtime = _now
   WHERE status = 'pending'
     AND reserved_at < (_now - _ttl_sec);

  SELECT id, partner, active, ends_at, max_redemptions, plan_scope
    INTO _cid, _partner, _active, _ends_at, _max, _scope
    FROM mkt_coupon WHERE code = _norm LIMIT 1;

  IF _cid IS NULL THEN
    SELECT 'CODE_NOT_FOUND' AS error;
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

  -- Plan targeting. Enforced HERE rather than only in the checkout caller:
  -- reserve is the anti-cheat boundary every redemption must pass, so a
  -- hand-crafted request that names a different plan than the UI offered
  -- still cannot spend a Team-only code on Business.
  -- 'all' (and a legacy empty value) means "no restriction".
  SET _scope = LOWER(NULLIF(TRIM(IFNULL(_scope, '')), ''));
  IF _scope IS NOT NULL AND _scope <> 'all'
     AND _scope <> LOWER(TRIM(IFNULL(_plan, ''))) THEN
    SELECT 'COUPON_PLAN_MISMATCH' AS error, _norm AS code,
           _scope AS plan_scope, _plan AS requested_plan;
    LEAVE proc;
  END IF;

  -- Live deal already held by this email?
  SELECT id INTO _existing_id
    FROM mkt_coupon_redemption
   WHERE email = _em AND status IN ('pending', 'confirmed')
   ORDER BY FIELD(status, 'confirmed', 'pending'), id DESC
   LIMIT 1;

  IF _existing_id IS NOT NULL THEN
    -- Idempotent re-reserve of the same pending code (retry checkout).
    IF EXISTS (
      SELECT 1 FROM mkt_coupon_redemption
       WHERE id = _existing_id AND status = 'pending' AND code = _norm
    ) THEN
      UPDATE mkt_coupon_redemption
         SET uid = IFNULL(NULLIF(_uid, ''), uid),
             plan = IFNULL(NULLIF(_plan, ''), plan),
             period = IFNULL(NULLIF(_period, ''), period),
             entity_type = IFNULL(NULLIF(_entity_type, ''), entity_type),
             stripe_session_id = IFNULL(NULLIF(_session_id, ''), stripe_session_id),
             reserved_at = _now,
             mtime = _now
       WHERE id = _existing_id;
      SELECT r.*, c.percent_off, c.duration_months, c.trial_days, c.stripe_coupon_id, c.kind
        FROM mkt_coupon_redemption r
        INNER JOIN mkt_coupon c ON c.id = r.coupon_id
       WHERE r.id = _existing_id;
      LEAVE proc;
    END IF;
    SELECT 'EMAIL_ALREADY_USED' AS error, _em AS email;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _used FROM mkt_coupon_redemption
   WHERE coupon_id = _cid AND status IN ('pending', 'confirmed');
  IF _max IS NOT NULL AND _max > 0 AND _used >= _max THEN
    SELECT 'CODE_EXHAUSTED' AS error, _norm AS code, _used AS used_count, _max AS max_redemptions;
    LEAVE proc;
  END IF;

  INSERT INTO mkt_coupon_redemption
    (coupon_id, code, partner, email, uid, plan, period, entity_type,
     stripe_session_id, status, reserved_at, ctime, mtime)
  VALUES
    (_cid, _norm, IFNULL(_partner, ''), _em, _uid, _plan, _period, _entity_type,
     NULLIF(_session_id, ''), 'pending', _now, _now, _now);

  SELECT r.*, c.percent_off, c.duration_months, c.trial_days, c.stripe_coupon_id, c.kind
    FROM mkt_coupon_redemption r
    INNER JOIN mkt_coupon c ON c.id = r.coupon_id
   WHERE r.id = LAST_INSERT_ID();
END $

DELIMITER ;
