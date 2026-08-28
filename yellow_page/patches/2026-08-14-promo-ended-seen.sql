-- =========================================================
-- promo_launch30.ended_seen_at — the trial-ended decision gate
--
-- When the 1-month Team trial lapses, promoExpiryWorker clears the
-- entitlement and the org drops to Free. Until now the client said nothing
-- about it outside the Billing page: anyone not looking at that exact screen
-- watched their workspace lose Team features with no explanation.
--
-- The trial-ended modal (prototype 2026-08-14) is a DECISION GATE, not a
-- notice: no close button, and it comes back on every home mount until the
-- owner picks Upgrade or Continue on Free. This column records that they
-- picked — which is a different thing from the existing *_seen_at columns.
-- Those mean "we showed it once, never again". This one means "the choice
-- has been made", and it is the only reason the modal ever stops appearing.
--
-- Nullable and unset for every existing row, so an org whose trial already
-- lapsed sees the gate on its next home mount. That is intended: they never
-- got the choice.
-- =========================================================
ALTER TABLE `promo_launch30`
  ADD COLUMN IF NOT EXISTS `ended_seen_at` int(11) unsigned DEFAULT NULL
  COMMENT 'owner answered the trial-ended gate (upgrade or continue-free)'
  AFTER `welcome_seen_at`;
