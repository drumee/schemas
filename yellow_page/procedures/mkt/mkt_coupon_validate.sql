DELIMITER $

-- =========================================================
-- mkt_coupon_validate
-- Read-only preview of what `mkt_coupon_reserve` would answer, so the
-- checkout form can price an "Apply" click WITHOUT consuming a
-- redemption. Same checks, same error codes, in the same order — the
-- two must not drift, or Apply would green-light a code that reserve
-- then refuses at the actual purchase.
--
-- Deliberately writes nothing: no pending row, and no TTL sweep. It
-- cannot release stale holds like reserve does, so instead it IGNORES
-- them (_ttl_sec, same default) when counting — otherwise Apply would
-- report EMAIL_ALREADY_USED / CODE_EXHAUSTED for holds that reserve is
-- about to free, refusing a purchase that would in fact go through.
--
-- A code the caller already holds pending is valid to them (reserve is
-- idempotent for that case), so it previews as OK rather than as
-- EMAIL_ALREADY_USED.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_validate`$
CREATE PROCEDURE `mkt_coupon_validate`(
  IN _code    VARCHAR(64),
  IN _email   VARCHAR(255),
  IN _plan    VARCHAR(32),
  IN _ttl_sec INT
)
proc: BEGIN
  DECLARE _cid INT UNSIGNED;
  DECLARE _active TINYINT;
  DECLARE _ends_at INT UNSIGNED;
  DECLARE _max INT UNSIGNED;
  DECLARE _used INT UNSIGNED;
  DECLARE _scope VARCHAR(32);
  DECLARE _now INT UNSIGNED;
  DECLARE _norm VARCHAR(64);
  DECLARE _em VARCHAR(255);
  DECLARE _held_other INT UNSIGNED;
  DECLARE _stale_before INT UNSIGNED;

  SET _now = UNIX_TIMESTAMP();
  SET _norm = UPPER(TRIM(_code));
  SET _em = LOWER(TRIM(IFNULL(_email, '')));
  -- Same default as reserve, so both age holds out at the same moment.
  SET _ttl_sec = IFNULL(NULLIF(_ttl_sec, 0), 86400);
  SET _stale_before = _now - _ttl_sec;

  IF _norm IS NULL OR _norm = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  SELECT id, active, ends_at, max_redemptions, plan_scope
    INTO _cid, _active, _ends_at, _max, _scope
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
  IF _scope IS NOT NULL AND _scope <> 'all'
     AND _scope <> LOWER(TRIM(IFNULL(_plan, ''))) THEN
    SELECT 'COUPON_PLAN_MISMATCH' AS error, _norm AS code,
           _scope AS plan_scope, _plan AS requested_plan;
    LEAVE proc;
  END IF;

  -- A live deal on a DIFFERENT code blocks this one (1 email = 1 deal).
  -- Holding this same code is fine: reserve would just refresh it.
  --
  -- An ABANDONED pending does not block anything: reserve releases holds
  -- older than _ttl_sec before it checks, so counting them here made Apply
  -- refuse a code that Proceed then accepted — the shopper was told their
  -- valid code was used up and stopped. Confirmed rows always count; only
  -- pendings age out.
  IF _em <> '' THEN
    SELECT COUNT(*) INTO _held_other
      FROM mkt_coupon_redemption
     WHERE email = _em
       AND code <> _norm
       AND (status = 'confirmed'
            OR (status = 'pending' AND reserved_at >= _stale_before));
    IF _held_other > 0 THEN
      SELECT 'EMAIL_ALREADY_USED' AS error, _em AS email;
      LEAVE proc;
    END IF;
  END IF;

  -- Same reasoning for the redemption cap: a slot held by a stale pending is
  -- one reserve would free, so it must not read as exhausted here.
  SELECT COUNT(*) INTO _used FROM mkt_coupon_redemption
   WHERE coupon_id = _cid
     AND (status = 'confirmed'
          OR (status = 'pending' AND reserved_at >= _stale_before));
  IF _max IS NOT NULL AND _max > 0 AND _used >= _max THEN
    SELECT 'CODE_EXHAUSTED' AS error, _norm AS code,
           _used AS used_count, _max AS max_redemptions;
    LEAVE proc;
  END IF;

  SELECT code, partner, kind, plan_scope, percent_off, duration_months,
         trial_days, ends_at
    FROM mkt_coupon WHERE id = _cid LIMIT 1;
END $

DELIMITER ;
