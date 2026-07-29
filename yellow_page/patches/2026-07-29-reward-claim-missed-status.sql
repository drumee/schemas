-- =========================================================
-- reward_claim.status — 'missed'
--
-- The claim-reward campaign is capped at a fixed number of
-- slots (100 by default, `reward_conf` sysconf). 'missed' is
-- the terminal state for a user who was invited but was told
-- the reward is gone: either they arrived after the cap closed
-- (the desk gate shows the sold-out screen instead of the
-- flow), or they finished while the last slot was taken by
-- someone else and reward_claim_track refused the award.
--
-- Comment-only: nothing in the column's type or default
-- changes, and no existing row is touched. The rank order that
-- makes 'missed' stick lives in reward_claim_track, not here.
--
-- MODIFY rather than a conditional ALTER because re-running it
-- is a no-op — the comment is simply written again.
-- =========================================================
ALTER TABLE `reward_claim`
  MODIFY COLUMN `status` varchar(16) NOT NULL DEFAULT 'emailed'
  COMMENT 'emailed | clicked | started | dropped | missed | done';

ALTER TABLE `reward_claim`
  MODIFY COLUMN `completed_count` int(11) unsigned NOT NULL DEFAULT 0
  COMMENT 'Times this user has ever finished; survives a re-arm. > 0 holds one of the campaign''s limited slots';
