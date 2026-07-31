DELIMITER $

-- =========================================================
-- reward_expiry_due
--
-- Who needs telling that their claim-reward term is ending, and
-- has not been told at that point yet.
--
-- QUERY ONLY. It writes nothing, sends nothing and decides
-- nothing beyond "this user, at this stage". The worker
-- (server-team offline/workers/rewardExpiryWorker.js) does the
-- sending and records the result. Keeping the selection in SQL
-- and the delivery in JS means the hard part -- who qualifies --
-- is testable with a SELECT and no mail server.
--
-- NOTHING HERE IS LOAD-BEARING FOR CORRECTNESS. The term ends at
-- READ time, in get_quota / disk_limit / disk_free /
-- my_disk_limit. If this proc is never called, or the worker is
-- never installed, the allowance still drops on the right day and
-- enforcement still holds -- users simply are not warned. That is
-- the intended failure mode: a notification feature must not be
-- able to break the entitlement it describes.
--
-- ONLY USERS WHO WILL ACTUALLY BE AFFECTED
--
-- A rewarded user under the free allowance loses nothing when the
-- term ends: the number changes, their experience does not.
-- Mailing them is noise, and with ~100 people in the campaign
-- noise is expensive. So the usage test is part of the SELECT,
-- not a courtesy the caller might forget.
--
-- Usage is the owner's own total -- hubs they own plus their own
-- desk -- summed from yp.disk_usage: the same pair
-- directory/my_disk_limit.sql adds up and the same one the
-- entitlement is enforced against, so "over quota" here means
-- what it means everywhere else.
--
-- The allowance is READ from the seeded free row, not written as
-- 5000000000. The free plan has already moved once (20 GB -> 5 GB,
-- 2026-07-24-migrate-free-to-new-allowance.sql) and a hardcoded
-- figure would quietly mis-select the whole population next time.
--
-- STAGES, AND WHY THE GUARD IS "NOT SENT" NOT "DAY 30"
--
-- Three touches: 30 days out, 7 days out, and the day the term
-- ends. `stage` is the most urgent threshold the user has REACHED
-- -- MIN over the thresholds that days_left has passed -- and the
-- row is returned only if no notice has been recorded at that
-- stage.
--
-- That is the whole reason there is no new table. A
-- `days_left = 30` test is true for exactly 24 hours and never
-- comes back, so a cron that missed one night would skip that
-- warning forever. Asking "have they been told at this stage"
-- means a worker that was down catches up on its next run --
-- which, for something that happens once in five years, is the
-- difference between a warning and none.
--
-- Taking the most urgent REACHED stage also handles the catch-up
-- correctly: a user first seen at 5 days out is due the 7-day
-- notice, not a "30 days remaining" mail that is already false.
-- The worker records the skipped stages as superseded so they do
-- not fire later.
--
-- contact_activity is the ledger AND the in-app notification: the
-- row written to remember the send is the row the activity feed
-- renders. One write, two purposes, and no table that exists only
-- to hold a checkbox.
-- =========================================================
DROP PROCEDURE IF EXISTS `reward_expiry_due`$
CREATE PROCEDURE `reward_expiry_due`()
BEGIN
  DECLARE _free_disk BIGINT UNSIGNED DEFAULT 0;

  -- The allowance an expired reward falls back to. Scalar subquery so a missing
  -- seed row yields NULL rather than raising NOT FOUND.
  SET _free_disk = IFNULL((
    SELECT CAST(IFNULL(JSON_VALUE(quota, '$.disk'), 0) AS UNSIGNED)
      FROM quota WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1 LIMIT 1), 0);

  -- Owner totals once, not per candidate row.
  DROP TEMPORARY TABLE IF EXISTS _reward_usage;
  CREATE TEMPORARY TABLE _reward_usage (
    uid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL PRIMARY KEY,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );
  INSERT INTO _reward_usage (uid, used_bytes)
  SELECT uid, SUM(used_bytes) FROM (
    SELECT h.owner_id AS uid, SUM(du.size) AS used_bytes
      FROM disk_usage du INNER JOIN hub h ON du.hub_id = h.id
     WHERE h.owner_id IS NOT NULL
     GROUP BY h.owner_id
    UNION ALL
    SELECT dm.id AS uid, SUM(du.size) AS used_bytes
      FROM disk_usage du INNER JOIN drumate dm ON du.hub_id = dm.id
     GROUP BY dm.id
  ) parts
  GROUP BY uid;

  SELECT
    q.payer_id                         AS uid,
    d.email,
    d.fullname,
    JSON_VALUE(d.profile, '$.lang')    AS lang,
    q.period_end,
    FLOOR((CAST(q.period_end AS SIGNED) - CAST(UNIX_TIMESTAMP() AS SIGNED)) / 86400) AS days_left,
    u.used_bytes,
    _free_disk                         AS free_bytes,
    -- What they must clear to upload again. Computed here so the email copy
    -- cannot get the arithmetic wrong.
    GREATEST(CAST(u.used_bytes AS SIGNED) - CAST(_free_disk AS SIGNED), 0) AS excess_bytes,
    -- The most urgent threshold REACHED. days_left 20 -> 30; 5 -> 7; 0 -> 0.
    (SELECT MIN(s.stage)
       FROM (SELECT 30 AS stage UNION ALL SELECT 7 UNION ALL SELECT 0) s
      WHERE FLOOR((CAST(q.period_end AS SIGNED) - CAST(UNIX_TIMESTAMP() AS SIGNED)) / 86400) <= s.stage) AS stage
  FROM quota q
  INNER JOIN drumate d       ON d.id  = q.payer_id
  INNER JOIN _reward_usage u ON u.uid = q.payer_id
  WHERE q.source = 'reward'
    -- Still live: a term that already lapsed is past warning.
    --
    -- This predicate does NOT protect the days_left arithmetic above it.
    -- quota.period_end is BIGINT UNSIGNED, so `period_end - UNIX_TIMESTAMP()`
    -- on a lapsed row does not go negative, it raises
    --   ERROR 1690 (22003): BIGINT UNSIGNED value is out of range
    -- and takes the whole run down with it. SQL does not promise to evaluate
    -- WHERE predicates in written order, so this guard running first is the
    -- optimiser's choice, not a rule -- which is why every one of those
    -- expressions CASTs to SIGNED rather than relying on being reached second.
    -- A lapsed reward row exists in the wild (stage, term ended 2026-07-27),
    -- and this worker is designed to fail silently, so the failure would have
    -- been a warning that simply never arrived.
    AND IFNULL(q.period_end, 0) > UNIX_TIMESTAMP()
    -- Inside the first threshold. Outside it there is nothing to say yet.
    AND FLOOR((CAST(q.period_end AS SIGNED) - CAST(UNIX_TIMESTAMP() AS SIGNED)) / 86400) <= 30
    -- Over the allowance they are about to fall back to.
    AND u.used_bytes > _free_disk
    -- Not already told at THAT stage. The guard -- see the header.
    AND NOT EXISTS (
      SELECT 1 FROM contact_activity ca
       WHERE ca.target_uid = q.payer_id
         AND ca.event = 'reward_expiry_warning'
         AND CAST(JSON_VALUE(ca.data, '$.stage') AS SIGNED) =
             (SELECT MIN(s2.stage)
                FROM (SELECT 30 AS stage UNION ALL SELECT 7 UNION ALL SELECT 0) s2
               WHERE FLOOR((CAST(q.period_end AS SIGNED) - CAST(UNIX_TIMESTAMP() AS SIGNED)) / 86400) <= s2.stage))
  ORDER BY stage ASC, u.used_bytes DESC;

  DROP TEMPORARY TABLE IF EXISTS _reward_usage;
END $

DELIMITER ;
