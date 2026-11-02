-- TEAM1: Team plan, first monthly cycle $1.00, then list price ($29/month).
-- amount_off = 2900 - 100 = 2800 cents, duration_months = 0 (Stripe 'once').
-- Ends 2026-11-30 23:59:59 UTC (1796083199). Apply AFTER
-- add_offer_rules_to_mkt_coupon.sql. INSERT IGNORE: re-running never resets a
-- coupon someone has since edited (uni_code).
INSERT IGNORE INTO `mkt_coupon`
  (`code`, `partner`, `kind`, `plan_scope`, `period_scope`, `percent_off`,
   `amount_off`, `duration_months`, `trial_days`, `active`, `ends_at`,
   `max_redemptions`, `new_only`, `once_per_card`, `once_per_domain`,
   `block_disposable`, `exclusive`, `notes`, `created_by`, `ctime`, `mtime`)
VALUES
  ('TEAM1', 'Iris', 'kol_discount', 'team', 'month', 0,
   2800, 0, 0, 1, 1796083199,
   NULL, 1, 1, 1,
   1, 1, 'First month $1 then $29/month. Signup link ?offer=TEAM1.', NULL,
   UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
