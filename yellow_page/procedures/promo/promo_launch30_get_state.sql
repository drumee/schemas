DELIMITER $

-- =========================================================
-- promo_launch30_get_state
-- The caller's own LAUNCH30 row, or nothing (never seen, never
-- claimed) if none exists yet. Node decides eligibility from
-- this plus the caller's live plan (get_quota) — this proc is
-- a plain lookup, not a gate.
-- =========================================================
DROP PROCEDURE IF EXISTS `promo_launch30_get_state`$
CREATE PROCEDURE `promo_launch30_get_state`(
  IN _payer_id VARCHAR(16)
)
BEGIN
  SELECT status, org_id, domain_id, claimed_at, trial_ends_at, expired_at,
         home_seen_at, billing_seen_at, welcome_seen_at, ended_seen_at
  FROM promo_launch30
  WHERE payer_id = _payer_id
  LIMIT 1;
END $

DELIMITER ;
