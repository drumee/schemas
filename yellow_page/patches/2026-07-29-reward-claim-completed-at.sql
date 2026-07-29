-- =========================================================
-- reward_claim.completed_at
--
-- WHEN the user won their slot, which is the start of the
-- 5-year term reward_grant_storage writes into
-- yp.quota.period_end.
--
-- `mtime` cannot serve: it moves on every track post and is
-- bumped again by reward_claim_emailed on a re-arm, so a user
-- mailed a second wave would silently have their term restarted
-- from the day of the mail. The completion date has to be a
-- fact that nothing later touches.
--
-- Written ONCE, on the first GRANTED completion, and never
-- overwritten -- a re-armed user finishing a second time is a
-- second completion but not a second prize, so the clock must
-- not restart. Same rule, and the same reason, as
-- completed_count.
--
-- It also makes the grant re-materialisable. A rewarded user
-- who subscribes has their quota row overwritten by Stripe and
-- DELETEd again on cancel (payment_clear_entitlement); the
-- re-grant needs the ORIGINAL term, not five fresh years
-- handed out for cancelling a subscription.
--
-- Existing winners are backfilled from mtime by
-- 2026-07-29-reward-backfill-grant.sql, which is the best
-- available evidence for rows written before this column
-- existed. Left at 0 here rather than guessed at in the ALTER,
-- so the backfill owns that decision in one place.
-- =========================================================
ALTER TABLE `reward_claim`
  ADD COLUMN IF NOT EXISTS `completed_at` int(11) unsigned NOT NULL DEFAULT 0
  COMMENT 'When the slot was first won; start of the reward term. 0 = never won'
  AFTER `completed_count`;
