-- Migrate FREE rows still holding the pre-rebuild 20 GB onto the new 5 GB.
--
-- The pricing patch rewrote rows whose plan was a retired NAME, and the org
-- backfill raised team/business disk. Neither touched `free`, which kept the
-- old 20 GB allowance — so free accounts still read as Free while holding four
-- times what the plan now grants.
--
-- WHY THIS ONE HAS A GUARD
--   This is the only migration that REDUCES an allowance, and reducing below
--   what someone already stores puts them instantly over quota: uploads start
--   failing and the storage alerts fire, for a change they did not ask for.
--   Measured on stage before writing this: of five rows still at 20 GB, one
--   was storing 13 GB.
--
--   So a row is only lowered when the domain's live usage still fits in the new
--   allowance. Accounts above it keep the larger figure and are listed by the
--   SELECT below — they need a decision (grandfather, ask them to clear space,
--   or offer an upgrade), not a silent squeeze.
--
-- Idempotent: rows already at the catalog value no longer match.
UPDATE `yp`.`quota` q
  JOIN `yp`.`plan` p
    ON p.plan_code = 'free' AND p.entity_type = 'user'
   AND p.active = 1 AND p.currency = 'usd'
  LEFT JOIN `yp`.`quota_usage` qu ON qu.domain_id = q.domain_id
   SET q.quota = JSON_SET(q.quota,
         '$.disk',      CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED),
         '$.desk_disk', CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED),
         '$.hub_disk',  CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED)),
       q.mtime = UNIX_TIMESTAMP()
 WHERE q.plan = 'free'
   AND CAST(IFNULL(JSON_VALUE(q.quota, '$.disk'), 0) AS UNSIGNED)
       > CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED)
   -- only where the live usage still fits the new allowance
   AND IFNULL(qu.actual_usage, 0)
       <= CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED);

-- Left behind on purpose: free accounts storing more than the new allowance.
-- Review these; they are NOT migrated by the statement above.
SELECT q.payer_id, q.domain_id,
       CAST(JSON_VALUE(q.quota, '$.disk') AS UNSIGNED) / 1000000000 AS current_gb,
       ROUND(IFNULL(qu.actual_usage, 0) / 1000000000, 2)            AS used_gb
  FROM `yp`.`quota` q
  LEFT JOIN `yp`.`quota_usage` qu ON qu.domain_id = q.domain_id
 WHERE q.plan = 'free'
   AND CAST(IFNULL(JSON_VALUE(q.quota, '$.disk'), 0) AS UNSIGNED) > 5000000000;
