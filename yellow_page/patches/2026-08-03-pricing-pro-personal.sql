-- Pro returns to the catalog — as a PERSONAL plan this time.
--
--   PRO  $5/mo · $50/yr — 50 GB, 1 hub, 1 member + unlimited guests,
--        unlimited share links, 7-day version history, no admin panel.
--        Positioning: "For one person who shares" (pricing table 2026-08-03).
--
-- This is NOT the old `pro`. The retired tier (2026-07-24 patch) was the B2C
-- entry ORG plan: entity_type 'user' but organization:1, 5 included seats and
-- a pro_seat add-on. The new Pro sits between Free and Team as a strictly
-- personal tier: organization:0, no seats to add, no admin console. The old
-- EUR rows stay retired (active=0); these are new USD rows.
--
-- seat: 1, deliberately — NOT 0. `isFreeSoloPlan()` (ui-team libs/billing)
-- reads seat===0 as "Free solo: block every invite", and Pro's whole pitch is
-- unlimited guests. 1 = the member themselves, and keeps every existing
-- `if (!quota.seat)` check meaning what it meant.
--
-- history_length 7 per the pricing table (Free none, Team 30, Business 365).
--
-- IDEMPOTENT + NON-DESTRUCTIVE: INSERT IGNORE; stripe_price_id seeded NULL
-- here and set per environment out-of-band (sandbox and live are separate
-- Stripe accounts, price ids are never portable).

INSERT IGNORE INTO `yp`.`plan`
  (plan_code, entity_type, period, currency, quota, features, active, stripe_price_id)
VALUES
  ('pro','user','month','usd',
   JSON_OBJECT('plan','pro','disk',50000000000,'desk_disk',50000000000,'hub_disk',50000000000,
               'seat',1,'organization',0,'history_length',7,
               'private_hub',1,'share_hub',1,'public_hub',0),
   JSON_OBJECT(), 1, NULL),
  ('pro','user','year','usd',
   JSON_OBJECT('plan','pro','disk',50000000000,'desk_disk',50000000000,'hub_disk',50000000000,
               'seat',1,'organization',0,'history_length',7,
               'private_hub',1,'share_hub',1,'public_hub',0),
   JSON_OBJECT(), 1, NULL);

-- The 2026-07-24 patch's blanket retirement must not undo this on a fresh
-- database where patches replay in order: it deactivates plan_code='pro'
-- globally. Re-activate ONLY the USD personal rows created above.
UPDATE `yp`.`plan` SET active = 1
 WHERE plan_code = 'pro' AND currency = 'usd' AND entity_type = 'user';
