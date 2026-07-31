-- =========================================================
-- Backfill the claim-reward prize for users who already won it.
--
-- The campaign awarded a SLOT and nothing else until
-- reward_grant_storage existed: reward_claim_track bumped
-- completed_count, the widget said "5 years of unlimited
-- storage", and every resolver went on handing the user 5 GB.
-- Everyone who finished before that fix holds one of the
-- campaign's 100 places and has received nothing for it.
--
-- They are also the campaign's earliest and most engaged
-- users, so "going forward only" would have rewarded everybody
-- EXCEPT the people who responded fastest.
--
-- TERM DATED FROM THEIR OWN COMPLETION, not from this patch.
-- They were promised five years at the moment they finished.
-- completed_at does not exist on rows written before
-- 2026-07-29-reward-claim-completed-at.sql, so it is seeded
-- from mtime first — the best available evidence, and honest
-- about being an approximation. mtime moves on later posts, so
-- for a user who was re-armed and re-mailed this can read
-- LATER than the real completion; that errs towards giving
-- them slightly more, which is the right direction to be wrong
-- in.
--
-- PERSONAL ONLY, matching the grant path. Every resolver is
-- tenant-first, so a personal row written for a user inside an
-- org domain is never read — it would be a row that looks like
-- a prize and behaves like nothing. Those users are listed by
-- the second SELECT instead of being silently skipped.
--
-- IDEMPOTENT. NOT EXISTS keeps it off any row that already has
-- an entitlement (notably a live source='stripe' one, which
-- must not be downgraded to a reward), and the ON DUPLICATE
-- clause only ever refreshes a row this patch itself wrote.
-- Re-running changes nothing.
-- =========================================================

-- 1. Seed the term origin for winners recorded before the column existed.
UPDATE `yp`.`reward_claim`
   SET completed_at = mtime
 WHERE completed_count > 0
   AND completed_at = 0
   AND mtime > 0;

-- 2. Grant. 9223372036854775807 is the BIGINT unlimited sentinel; $.unlimited
--    is the real signal but $.disk must carry a number or the resolvers'
--    `_q_disk - used` arithmetic reads 0 and locks the user out (see
--    reward_grant_storage). Non-storage entitlements come from the live free
--    plan row so they track it.
INSERT INTO `yp`.`quota`
  (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
SELECT
  d.domain_id,
  rc.uid,
  'reward-5y',
  JSON_SET(
    IFNULL(
      (SELECT p.quota FROM `yp`.`plan` p
        WHERE p.plan_code = 'free' AND p.entity_type = 'user' AND p.active = 1
        LIMIT 1),
      JSON_OBJECT('seat', 0, 'organization', 0, 'history_length', 0, 'private_hub', 1)
    ),
    '$.plan',      'reward-5y',
    '$.unlimited', TRUE,
    '$.disk',      9223372036854775807,
    '$.desk_disk', 9223372036854775807,
    '$.hub_disk',  9223372036854775807
  ),
  'reward',
  UNIX_TIMESTAMP(FROM_UNIXTIME(rc.completed_at) + INTERVAL 5 YEAR),
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP()
FROM `yp`.`reward_claim` rc
INNER JOIN `yp`.`drumate` d ON d.id = rc.uid
WHERE rc.completed_count > 0
  AND rc.completed_at > 0
  AND d.domain_id = 1                    -- personal only; org members are listed below
  AND NOT EXISTS (
    SELECT 1 FROM `yp`.`quota` q
     WHERE q.domain_id = d.domain_id AND q.payer_id = rc.uid
  )
ON DUPLICATE KEY UPDATE
  quota      = VALUES(quota),
  period_end = VALUES(period_end),
  mtime      = UNIX_TIMESTAMP();

-- 3. The residue — winners this patch did NOT grant, and why. Review these:
--    an org member's reward needs a decision (they are already covered by the
--    org allowance), and a `stripe` holder already has more than the reward
--    gives, but will fall back to it when they cancel
--    (payment_clear_entitlement re-grants).
SELECT
  rc.uid,
  d.email,
  d.domain_id,
  FROM_UNIXTIME(rc.completed_at) AS completed_at,
  -- q.source is ascii_general_ci and the literals here are utf8mb4, which a
  -- CASE refuses to mix ("Illegal mix of collations", ERROR 1271) — it aborts
  -- the whole statement, so the report that tells an operator who was NOT
  -- granted would be the one thing in this patch that does not run. Converted
  -- explicitly rather than left to coercion.
  CASE
    WHEN d.id IS NULL           THEN 'no drumate row'
    WHEN d.domain_id > 1        THEN 'org member - covered by the org entitlement'
    WHEN q.payer_id IS NOT NULL THEN CONCAT('already entitled: ',
                                     CONVERT(IFNULL(q.source, 'free') USING utf8mb4))
    WHEN rc.completed_at = 0    THEN 'no completion date and no mtime to seed it from'
    ELSE 'granted'
  END AS outcome
FROM `yp`.`reward_claim` rc
LEFT JOIN `yp`.`drumate` d ON d.id = rc.uid
LEFT JOIN `yp`.`quota` q
       ON q.domain_id = d.domain_id AND q.payer_id = rc.uid AND IFNULL(q.source,'free') <> 'reward'
WHERE rc.completed_count > 0
  AND (d.id IS NULL OR d.domain_id > 1 OR q.payer_id IS NOT NULL OR rc.completed_at = 0);
