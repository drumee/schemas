-- Backfill: org rows still carrying the PRE-REBUILD per-seat allowance.
--
-- 2026-07-24-pricing-usd-team-business.sql rewrote quota rows whose plan was a
-- retired NAME ('Pro', 'Drumee Plus', 'advanced'). Rows already named 'team'
-- were left alone — but under the old model 'team' was PER SEAT, and
-- payment_apply_entitlement stored `per-seat disk x seats`, typically the bare
-- 50 GB per-seat figure. Those orgs read as Team while holding half the
-- storage the plan now grants, and would only be corrected on their next
-- renewal, whenever that happens to fall.
--
-- ONLY EVER RAISES. The disk is taken from the active catalog row and applied
-- solely where the stored value is LOWER, so an org that legitimately holds
-- more (a bigger negotiated allowance, a surviving storage add-on) keeps it.
-- Nobody loses storage to this patch.
--
-- Idempotent: a second run matches nothing, because the values now agree.
UPDATE `yp`.`quota` q
  JOIN `yp`.`plan` p
    ON p.plan_code = q.plan
   AND p.entity_type = 'org'
   AND p.active = 1
   AND p.currency = 'usd'
   AND p.period = 'month'
   SET q.quota = JSON_SET(q.quota,
         '$.disk', CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED),
         '$.seat', CAST(JSON_VALUE(p.quota, '$.seat') AS UNSIGNED)),
       q.mtime = UNIX_TIMESTAMP()
 WHERE q.plan IN ('team', 'business')
   AND CAST(IFNULL(JSON_VALUE(q.quota, '$.disk'), 0) AS UNSIGNED)
       < CAST(JSON_VALUE(p.quota, '$.disk') AS UNSIGNED);
