-- The 7-day no-card Team trial behind the $1 offer (promo.redeem shape: no
-- percent off, trial_days > 0). The offer closes 2026-11-30 23:59:59 CET.
-- INSERT IGNORE keeps any later edit to the row. Replay-safe.
INSERT IGNORE INTO mkt_coupon
  (code, partner, kind, plan_scope, percent_off, duration_months, trial_days, active, ends_at, notes, ctime, mtime)
VALUES
  ('TEAM7FREE', 'team-1usd', 'warm_trial', 'team', 0, 0, 7, 1,
   UNIX_TIMESTAMP('2026-11-30 22:59:59'), 'Team $1 offer: 7 days free, no card',
   UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
