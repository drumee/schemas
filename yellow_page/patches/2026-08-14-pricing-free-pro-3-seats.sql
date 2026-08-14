-- =========================================================
-- Free and Pro get 3 member seats (pricing restructure, 1-pager 2026-08-14)
--
-- WHY: Free and Pro block every invite today, which kills the referral loop
-- at the moment it matters most. The 1-pager sets Free = 3 members and
-- Pro = 3 members, Team stays at 10.
--
-- SEAT IS A TOTAL, INCLUDING THE OWNER. _seatBudget computes
-- `free = seat - members - pending` where `members` already counts the owner,
-- so seat 3 means the owner plus two other people. Team's 10 is counted the
-- same way; the two tiers stay on one scale.
--
-- MEASURED ON PRODUCTION before writing this, because the seed file in this
-- repo has drifted from what is actually live:
--
--   plan      entity  period  active  seat     disk    stripe_price_id
--   free      user    free    1       0        5 GB    NULL
--   pro       user    month   1       1        50 GB   set
--   pro       user    year    1       1        50 GB   set
--   team      org     month   1       10       100 GB  set
--   business  org     month   1       100000   1 TB    set
--
-- Note Free is seat 0 live, not 1 as the 1-pager assumed. 0 was doing double
-- duty as "cannot invite" (`if (!quota.seat)` reads it that way, and
-- isFreeSoloPlan on the client treats it as solo-locked). Moving it to 3
-- retires that overload — the accompanying client change makes the block
-- purely seat-driven instead of keying off the plan NAME, otherwise Free
-- stays blocked no matter what this row says.
--
-- The pro rows are only touched where they exist. The seed in
-- yellow_page/tables/plan.sql carries no pro row at all (the B2C catalog was
-- retired in the 2026-07 rebuild and later re-activated on prod out of band),
-- so on a fresh database these UPDATEs simply match nothing. That drift is
-- real and worth closing separately; this patch does not paper over it.
--
-- RE-RUNNABLE: sets absolute values, not increments.
-- =========================================================

-- Free: 0 -> 3.
UPDATE `plan`
   SET `quota` = JSON_SET(`quota`, '$.seat', 3)
 WHERE `plan_code` = 'free'
   AND `entity_type` = 'user';

-- Pro: 1 -> 3, both billing periods.
UPDATE `plan`
   SET `quota` = JSON_SET(`quota`, '$.seat', 3)
 WHERE `plan_code` = 'pro'
   AND `entity_type` = 'user'
   AND `period` IN ('month', 'year');

-- Existing entitlements carry a snapshot of the quota taken when the plan was
-- applied, so a live Free/Pro account keeps its old seat number until
-- something re-applies. Bring them along, or nobody currently on those plans
-- sees the change until their next subscription event.
UPDATE `quota`
   SET `quota` = JSON_SET(`quota`, '$.seat', 3)
 WHERE JSON_VALUE(`quota`, '$.plan') IN ('free', 'pro')
   AND IFNULL(JSON_VALUE(`quota`, '$.seat'), 0) < 3;
