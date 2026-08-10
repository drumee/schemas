-- One row per PAID Stripe invoice. The single source of truth for every
-- revenue figure on the analytics dashboard.
--
-- WHY THIS EXISTS. yp.subscription_new is a CURRENT-STATE mirror — UNIQUE on
-- entity_id, one row per customer, ctime overwritten on every change — so it
-- cannot answer "how much did we bill in March". yp.subscription_history was
-- meant to be this ledger and has never had a writer (0 rows on stage); it is
-- left alone rather than revived, because its UNIQUE key
-- (subscription_id, payment_intent_id, entity_id) does not dedupe on the thing
-- Stripe actually identifies a payment by.
--
-- invoice_id IS THE IDEMPOTENCY KEY. Two writers touch this table — the
-- webhook (real time) and bin/revenue-reconcile.js (history + self-heal) — and
-- they must be safe to run over each other. Both go through
-- payment_ledger_upsert, which relies on this UNIQUE.
--
-- MINOR UNITS throughout, matching subscription_new.price (9900 = $99.00).
-- Never floats: a float cent total drifts once you SUM it over a year.
--
-- Collation follows yp exactly. The reward tables were built utf8mb4_unicode_ci
-- against a general_ci yp and every cross-schema join threw ERROR 1267.
CREATE TABLE IF NOT EXISTS `payment_ledger` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `invoice_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `subscription_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `customer_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Who the plan is FOR: an organisation id for org plans, a user id otherwise.
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- The human who pays. For an org plan entity_id is the ORGANISATION, so a
  -- plain drumate join yields NULL — visible on stage today for every business
  -- row. Resolved at write time from metadata.payer_id, else organisation.owner_id.
  `payer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- The address Stripe actually billed, denormalised on purpose: it is the
  -- truthful answer to "who paid this", it survives the payer changing address
  -- later, and it saves a three-way join on every page of the table.
  `email` varchar(190) DEFAULT NULL,
  `entity_type` enum('user','org') NOT NULL DEFAULT 'user',
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'team',
  `period` enum('month','year') NOT NULL DEFAULT 'month',
  `amount_paid` bigint(20) NOT NULL DEFAULT 0,
  `amount_refunded` bigint(20) NOT NULL DEFAULT 0,
  `currency` char(3) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'usd',
  -- STORED, not VIRTUAL, so it can carry an index and SUM() reads it off disk.
  `net_amount` bigint(20) AS (`amount_paid` - `amount_refunded`) STORED,
  -- subscription_create | subscription_cycle | subscription_update, straight
  -- from Stripe. Separates a first sale from a renewal from a proration.
  `billing_reason` varchar(40) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `paid_at` int(11) unsigned NOT NULL,
  `promo_code` varchar(64) DEFAULT NULL,
  `source` enum('webhook','reconcile') NOT NULL DEFAULT 'webhook',
  `ctime` int(11) unsigned NOT NULL,
  `mtime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `invoice_id` (`invoice_id`),
  KEY `paid_at` (`paid_at`),
  KEY `plan_paid` (`plan`,`paid_at`),
  KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
