-- Extra Team seats, sold as a recurring add-on.
--
-- The 2026-07 pricing rebuild made Team a flat plan with ten included members
-- and no way to grow past that except moving to Business. Teams that need an
-- eleventh member but nothing else Business offers had nowhere to go, so the
-- seat add-on comes back — this time attached to Team (entity_type='addon',
-- quantity = seats beyond the included ten) rather than to the retired B2C
-- Pro tier.
--
-- Price lives in STRIPE, not here: it is volume-tiered (under 10 extra seats
-- $3.00 each, 10 or more $2.90 each), which a single unit_amount column cannot
-- express. stripe_price_id stays NULL and is seeded per environment, since
-- sandbox and live are separate Stripe accounts.
--
-- quota JSON carries $.seat = 1 (one seat per unit) and deliberately no
-- $.disk: extra members share the plan's storage, they do not add to it.
--
-- IDEMPOTENT: INSERT IGNORE, so a re-run never clobbers an env's price id.
INSERT IGNORE INTO `yp`.`plan`
  (plan_code, entity_type, period, currency, quota, features, active, stripe_price_id)
VALUES
  ('team_seat','addon','month','usd', JSON_OBJECT('plan','team_seat','seat',1), JSON_OBJECT(), 1, NULL),
  ('team_seat','addon','year','usd',  JSON_OBJECT('plan','team_seat','seat',1), JSON_OBJECT(), 1, NULL);
