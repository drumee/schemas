-- Coupons need to be targetable at a single plan, not just "whatever paid
-- plan the buyer happens to pick". Until now the only plan gate lived in
-- payment.js as a hardcoded /^(team|business)$/ test applied to EVERY code,
-- so a partner code minted for Team was equally spendable on Business.
--
-- plan_scope is a single value on purpose (the ask is "one plan or all
-- plans", not an arbitrary subset):
--   'all'        → any plan checkout already supports (today: team|business)
--   '<plan_code>'→ that plan only, e.g. 'team' / 'business'
--
-- Default 'all' is exactly the current behaviour, so the 13 live coupons
-- keep working unchanged on deploy — this is additive, not a migration.
ALTER TABLE `mkt_coupon`
  ADD COLUMN IF NOT EXISTS `plan_scope` varchar(32)
    CHARACTER SET ascii COLLATE ascii_general_ci
    NOT NULL DEFAULT 'all'
    COMMENT "'all' or a single yp.plan.plan_code (team|business)"
    AFTER `kind`;
