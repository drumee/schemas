-- C1 Pro per-seat: seed the `pro_seat` add-on rows into yp.plan on EXISTING DBs.
--
-- The full seed lives in yellow_page/tables/plan.sql, but that file is
-- `CREATE TABLE IF NOT EXISTS` + `INSERT IGNORE` — on a prod/existing DB the
-- table already exists so the CREATE is a no-op and the new rows only land via
-- the INSERT IGNORE. This standalone patch carries JUST the two new rows so a
-- targeted deploy doesn't depend on re-running the whole table file.
--
-- ADDITIVE + IDEMPOTENT:
--   * INSERT IGNORE — new rows insert; if the rows already exist (UNIQUE
--     plan_code+entity_type+period+currency) they are skipped, so a re-run
--     never clobbers env-specific stripe_price_id values.
--   * entity_type 'addon' already exists in the enum (added with the storage
--     add-ons in P4) — NO ALTER TABLE / structural change is needed.
--   * stripe_price_id stays NULL here; the LIVE/test price ids are set
--     out-of-band per environment after creating the Stripe prices.
--
-- pro_seat = one extra Pro seat per unit. Pro's own quota carries $.seat=5
-- (included); seats beyond that become a recurring pro_seat line whose quantity
-- is the extra count. No $.disk — extra seats don't add storage on Pro.

INSERT IGNORE INTO `plan`
  (`plan_code`, `entity_type`, `period`, `currency`, `quota`, `features`, `active`, `stripe_price_id`)
VALUES
  ('pro_seat', 'addon', 'month', 'eur', JSON_OBJECT('plan', 'pro_seat', 'seat', 1), JSON_OBJECT(), 1, NULL),
  ('pro_seat', 'addon', 'year',  'eur', JSON_OBJECT('plan', 'pro_seat', 'seat', 1), JSON_OBJECT(), 1, NULL);
