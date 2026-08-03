DELIMITER $

-- =========================================================
-- mkt_coupon_redeem_due
-- Direct-redeemed coupons whose free period has run out and are not yet
-- reverted. Polled by promoExpiryWorker alongside promo_launch30_due.
--
-- The predicate is what defines a DIRECT grant: confirmed, carrying a
-- trial_ends_at, and with no Stripe subscription behind it. A redemption
-- that went through Checkout has stripe_subscription_id set and its end
-- date lives at Stripe — reverting it here would cancel a plan the
-- customer is still paying for.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_redeem_due`$
CREATE PROCEDURE `mkt_coupon_redeem_due`()
BEGIN
  SELECT id, code, email, uid, org_id, domain_id, plan, trial_ends_at
  FROM mkt_coupon_redemption
  WHERE status = 'confirmed'
    AND trial_ends_at IS NOT NULL
    AND trial_ends_at < UNIX_TIMESTAMP()
    AND org_id IS NOT NULL
    AND (stripe_subscription_id IS NULL OR stripe_subscription_id = '');
END $

DELIMITER ;
