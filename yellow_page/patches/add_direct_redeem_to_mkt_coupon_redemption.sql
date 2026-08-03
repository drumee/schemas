-- Direct redemption ("I have a code" → get the plan, no Stripe Checkout).
--
-- Until now every redemption ended as a Stripe subscription, so Stripe owned
-- the end date and the redemption row only needed to remember which session
-- produced it. A code redeemed directly has NO Stripe object at all (same
-- shape as the LAUNCH30 claim), which means nothing would ever end it — a
-- 90-day free_months grant would sit on the org forever. These columns are
-- what lets the expiry worker find and revert it:
--
--   trial_ends_at  when the granted free period lapses (NULL for the normal
--                  checkout path, where Stripe is the clock)
--   org_id/domain_id  the org that received the entitlement, needed to call
--                  payment_clear_entitlement on expiry — uid alone is not
--                  enough, the quota row is keyed by the ORG
--
-- A direct grant is therefore identifiable as:
--   status='confirmed' AND trial_ends_at IS NOT NULL AND stripe_subscription_id IS NULL
--
-- 'expired' joins the status enum so a lapsed grant is distinguishable from
-- one still running; it must be appended, not reordered, or existing rows
-- would silently change meaning.
ALTER TABLE `mkt_coupon_redemption`
  ADD COLUMN IF NOT EXISTS `trial_ends_at` int(11) unsigned DEFAULT NULL
    COMMENT 'Direct grant only: when the free period lapses' AFTER `confirmed_at`,
  ADD COLUMN IF NOT EXISTS `org_id` varchar(16)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'Direct grant only: org holding the entitlement' AFTER `trial_ends_at`,
  ADD COLUMN IF NOT EXISTS `domain_id` int(11) unsigned DEFAULT NULL
    COMMENT 'Direct grant only: domain of org_id' AFTER `org_id`;

ALTER TABLE `mkt_coupon_redemption`
  MODIFY COLUMN `status`
    enum('pending','confirmed','failed','released','expired')
    NOT NULL DEFAULT 'pending';

-- The expiry worker polls on exactly this predicate.
ALTER TABLE `mkt_coupon_redemption`
  ADD INDEX IF NOT EXISTS `idx_status_trial_end` (`status`, `trial_ends_at`);
