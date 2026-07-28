-- =========================================================
-- reward_claim: `clicked` joins the status vocabulary
--
-- Being MAILED stopped being the entitlement on its own. The
-- user has to follow the campaign link, so a new status sits
-- between 'emailed' and 'started', and only 'clicked' /
-- 'started' open the flow (see reward.get_state). Someone who
-- was sent the mail and simply logs in now gets nothing.
--
-- Column-comment only: 'clicked' fits the existing varchar(16)
-- and the ranking lives in reward_claim_track, so no data
-- change is needed. This keeps the deployed schema
-- self-documenting rather than drifting from the repo.
--
-- Rows already sitting at 'emailed' are deliberately NOT
-- migrated: we cannot know whether those people ever clicked,
-- and inventing a click would hand the flow to users who never
-- asked for it. They simply click the link when they get to it.
-- =========================================================
ALTER TABLE `reward_claim`
  MODIFY COLUMN `status` varchar(16) NOT NULL DEFAULT 'emailed'
  COMMENT 'emailed | clicked | started | dropped | done';
