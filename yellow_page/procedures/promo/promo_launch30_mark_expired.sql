DELIMITER $

-- =========================================================
-- promo_launch30_mark_expired
-- Flips a claimed row to expired once the worker has already
-- cleared the org's promo entitlement (payment_clear_entitlement
-- on _org_id — same call an org's Stripe cancel makes, so the
-- member falls back to their own per-user tier the same way).
-- Guarded on status='claimed' so a retried worker tick is a
-- no-op, not a second expired_at stamp.
-- =========================================================
DROP PROCEDURE IF EXISTS `promo_launch30_mark_expired`$
CREATE PROCEDURE `promo_launch30_mark_expired`(
  IN _payer_id VARCHAR(16)
)
BEGIN
  UPDATE promo_launch30
  SET status = 'expired', expired_at = UNIX_TIMESTAMP(), mtime = UNIX_TIMESTAMP()
  WHERE payer_id = _payer_id AND status = 'claimed';

  SELECT ROW_COUNT() AS expired;
END $

DELIMITER ;
