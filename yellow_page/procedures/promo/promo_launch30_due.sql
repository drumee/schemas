DELIMITER $

-- =========================================================
-- promo_launch30_due
-- Claimed trials whose 30 days have passed and are not yet
-- reverted. Polled by the expiry worker (mirrors
-- versionRetentionWorker/reminderWorker: plain setTimeout
-- self-rescheduler, the runtime ships Bull, not `cron`).
-- =========================================================
DROP PROCEDURE IF EXISTS `promo_launch30_due`$
CREATE PROCEDURE `promo_launch30_due`()
BEGIN
  SELECT payer_id, org_id, domain_id, trial_ends_at
  FROM promo_launch30
  WHERE status = 'claimed' AND trial_ends_at < UNIX_TIMESTAMP();
END $

DELIMITER ;
