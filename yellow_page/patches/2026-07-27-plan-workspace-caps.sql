-- Workspace (hub) caps per plan, and the same caps on every entitlement row
-- already granted.
--
-- The published pricing table sells "Workspaces: 1" on Free and Team and
-- "Multiple" on Business, and desk.check_quota (preproc of desk.create_hub)
-- has always been ready to enforce it: it reads $.private_hub / $.share_hub /
-- $.public_hub out of get_quota. Those keys were simply never written by the
-- 2026-07 catalog, so the cap was undefined, `cap - used` was NaN, and
-- `NaN <= 0` is false — the guard passed every single time and no plan ever
-- limited anything. (The NaN reading is fixed alongside this, in
-- server-team desk.js, so an absent cap now means "unlimited" on purpose
-- rather than by accident.)
--
-- Business deliberately gets NO keys: absent means unlimited, which is what
-- "Multiple" sells.
--
-- public_hub is 0 on both capped plans. The table does not offer a public
-- workspace tier, and leaving it absent would have made public hubs the
-- unlimited way around a private/share cap.
--
-- Idempotent: JSON_SET overwrites, so a re-run is a no-op.

-- 1. The catalog.
UPDATE `plan`
   SET quota = JSON_SET(quota, '$.private_hub', 1, '$.share_hub', 0, '$.public_hub', 0)
 WHERE plan_code = 'free' AND active = 1;

UPDATE `plan`
   SET quota = JSON_SET(quota, '$.private_hub', 1, '$.share_hub', 1, '$.public_hub', 0)
 WHERE plan_code = 'team' AND active = 1;

-- 2. Entitlements already granted. yp.quota holds a COPY of the plan's quota
-- JSON taken at payment time (payment_apply_entitlement), so rows written
-- before this patch carry no caps and would stay unlimited until the next
-- renewal rewrote them.
UPDATE `quota`
   SET quota = JSON_SET(quota, '$.private_hub', 1, '$.share_hub', 0, '$.public_hub', 0)
 WHERE LOWER(COALESCE(JSON_VALUE(quota, '$.plan'), plan)) = 'free';

UPDATE `quota`
   SET quota = JSON_SET(quota, '$.private_hub', 1, '$.share_hub', 1, '$.public_hub', 0)
 WHERE LOWER(COALESCE(JSON_VALUE(quota, '$.plan'), plan)) = 'team';

-- Business rows must not carry caps — clear any left by an earlier plan the
-- entitlement was upgraded from, or this patch would cap a plan that sells
-- "Multiple".
UPDATE `quota`
   SET quota = JSON_REMOVE(quota, '$.private_hub', '$.share_hub', '$.public_hub')
 WHERE LOWER(COALESCE(JSON_VALUE(quota, '$.plan'), plan)) IN ('business', 'sovereign', 'enterprise');
