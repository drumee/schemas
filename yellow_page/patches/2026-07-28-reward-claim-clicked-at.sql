-- =========================================================
-- reward_claim.clicked_at
--
-- `status` holds only the CURRENT state, and the flow moves
-- fast: clicked -> started -> dropped inside a few seconds.
-- So a click that worked perfectly left no trace, and the only
-- way to tell whether the CTA had been followed was to read
-- nginx access logs. Recording when it happened makes the
-- stage observable, and makes emailed -> clicked (the campaign
-- click-through rate) a number the dashboard can show.
--
-- Reset to 0 by a re-arm: a returning user has to click again,
-- so the timestamp belongs to the CURRENT attempt.
--
-- Rows already past 'clicked' are left at 0. We cannot know
-- when they clicked, and inventing a time would be worse than
-- an honest "unknown".
-- =========================================================
ALTER TABLE `reward_claim`
  ADD COLUMN IF NOT EXISTS `clicked_at` int(11) unsigned NOT NULL DEFAULT 0
  COMMENT 'When the CTA was followed for the current attempt; 0 = not yet'
  AFTER `step`;
