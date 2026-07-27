-- =========================================================
-- reward_claim.completed_count
--
-- Eligibility for the claim-reward flow moves from the browser
-- to this table: the gate now asks the server instead of
-- reading localStorage, so a send RE-ARMS a finished user by
-- resetting their row to 'emailed' (see reward_claim_emailed).
--
-- That reset would otherwise erase the fact that they ever
-- finished, so the completion is counted here instead. Anyone
-- with completed_count > 0 has claimed the reward at least
-- once, whatever `status` currently says.
--
-- Backfilled from the current state: rows already sitting at
-- 'done' completed exactly once as far as we can know.
-- =========================================================
ALTER TABLE `reward_claim`
  ADD COLUMN IF NOT EXISTS `completed_count` int(11) unsigned NOT NULL DEFAULT 0
  COMMENT 'Times this user has ever finished; survives a re-arm'
  AFTER `emailed_count`;

UPDATE `reward_claim` SET `completed_count` = 1
  WHERE `status` = 'done' AND `completed_count` = 0;
