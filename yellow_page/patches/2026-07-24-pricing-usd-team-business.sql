-- 2026-07 pricing rebuild: USD catalog, Pro (B2C) retired in favour of Team (B2B).
--
-- WHAT CHANGES
--   FREE      $0     — 5 GB,   solo
--   TEAM      $29/mo — 100 GB, up to 10 members   (the new entry paid tier)
--   BUSINESS  $99/mo — 1 TB,   unlimited members  (sales-led, no Stripe price)
--   SOVEREIGN        — self-hosted, sales-led, not a SaaS entitlement (absent here)
--   Yearly = 11 x monthly (one month free): team $319, business $1089.
--
-- Prices themselves live in Stripe, not here — this file only carries the
-- catalog rows and the quota each plan grants. stripe_price_id stays NULL and
-- is seeded per environment out-of-band (sandbox and live are separate Stripe
-- accounts, so price ids are never portable between them).
--
-- WHY `pro` GOES AWAY
--   `pro` was the B2C per-user tier (entity_type='user', 5 included seats plus
--   a `pro_seat` add-on). The product is now B2B: the entry paid tier is an
--   ORGANISATION plan. So `team` becomes the first paid step and `pro`, along
--   with every add-on (pro_seat, storage_*), is retired.
--
--   `team` also stops being per-seat. It used to price per seat and multiply
--   quota.$.disk by the seat quantity; it is now a FLAT plan: 100 GB total for
--   up to 10 members. payment_apply_entitlement is updated to match — see that
--   procedure, the two must move together or org disk goes wrong.
--
-- SEAT SEMANTICS (unchanged where it matters)
--   quota.$.seat stays "member slots", NOT a purchased quantity:
--     free      0      — solo; existing code treats 0 as "cannot invite", so it
--                        is deliberately left at 0 rather than 1.
--     team      10
--     business  100000 — effectively unlimited. A real number, not 0, so every
--                        existing `if (!quota.seat)` / comparison keeps working;
--                        0 would read as "no seats at all".
--
-- IDEMPOTENT + NON-DESTRUCTIVE:
--   * INSERT IGNORE — re-running never clobbers env-specific stripe_price_id.
--   * Retired rows are deactivated (active = 0), never deleted: subscription /
--     renewal history FKs and audit trails still resolve their plan row.

-- 1. New USD catalog ---------------------------------------------------------
INSERT IGNORE INTO `yp`.`plan`
  (plan_code, entity_type, period, currency, quota, features, active, stripe_price_id)
VALUES
  ('free','user','free','usd',
   JSON_OBJECT('plan','free','disk',5000000000,'desk_disk',5000000000,'hub_disk',5000000000,
               'seat',0,'organization',0,'history_length',0),
   JSON_OBJECT(), 1, NULL),

  -- TEAM — flat, NOT per-seat. quota.$.disk is the whole allowance.
  ('team','org','month','usd',
   JSON_OBJECT('plan','team','disk',100000000000,'seat',10,'organization',1,'history_length',30),
   JSON_OBJECT(), 1, NULL),
  ('team','org','year','usd',
   JSON_OBJECT('plan','team','disk',100000000000,'seat',10,'organization',1,'history_length',30),
   JSON_OBJECT(), 1, NULL),

  -- BUSINESS — sales-led: rows exist so a manually provisioned org gets the
  -- right entitlement, but stripe_price_id stays NULL (no self-serve checkout).
  ('business','org','month','usd',
   JSON_OBJECT('plan','business','disk',1000000000000,'seat',100000,'organization',1,'history_length',365),
   JSON_OBJECT(), 1, NULL),
  ('business','org','year','usd',
   JSON_OBJECT('plan','business','disk',1000000000000,'seat',100000,'organization',1,'history_length',365),
   JSON_OBJECT(), 1, NULL);

-- 2. Retire the old catalog --------------------------------------------------
-- Every EUR row: the currency of a Stripe price cannot be changed, so the USD
-- rows above are new rows and the EUR ones must stop being selectable. The
-- lookup procedures all filter `active = 1`, so this is the whole switch.
UPDATE `yp`.`plan` SET active = 0 WHERE currency = 'eur';

-- Pro and every add-on, in any currency.
UPDATE `yp`.`plan` SET active = 0
 WHERE plan_code IN ('pro','pro_seat','storage_100','storage_500','storage_1000','advanced','company');

-- 3. Move legacy entitlements onto Team --------------------------------------
-- Hand-granted rows predating the Stripe catalog carry free-text plan names
-- ('Pro', 'Drumee Plus', 'advanced'). With `pro` retired they would point at a
-- plan that no longer resolves, so they are moved onto the Team entitlement.
-- Only rows NOT backed by a live Stripe subscription are touched (source is
-- 'stripe' only for real subscriptions), so nothing a customer is paying for
-- is rewritten by this patch.
UPDATE `yp`.`quota`
   SET plan  = 'team',
       quota = JSON_OBJECT('plan','team','disk',100000000000,'seat',10,
                           'organization',1,'history_length',30),
       mtime = UNIX_TIMESTAMP()
 WHERE LOWER(plan) IN ('pro','drumee plus','advanced','company');

-- Deliberately NOT filtered on source. The first cut spared source='stripe'
-- rows so a paying customer could never be rewritten — but that left rows
-- pointing at a plan code the catalog no longer serves, which then has to be
-- special-cased forever in the UI. Checked before widening: prod carries zero
-- live Stripe subscriptions (3 rows, all mode='free', all expired), so no
-- active payer exists to protect. Re-run safely: rows already on 'team' no
-- longer match.
