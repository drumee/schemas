-- yp.plan is the catalog: stripe_price_id per (plan_code, entity_type, period,
-- currency) + the quota a plan grants. Price truth = Stripe.
-- NON-DESTRUCTIVE on re-apply: no DROP + INSERT IGNORE seed, so a manifest
-- re-deploy preserves the env-specific stripe_price_id values (set out-of-band).
CREATE TABLE IF NOT EXISTS `plan` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'free',
  `entity_type` enum('user','org','addon') NOT NULL DEFAULT 'user',
  `period` enum('free','month','year') NOT NULL DEFAULT 'free',
  `currency` char(3) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'eur',
  `stripe_price_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `stripe_product_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `quota` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`quota`)),
  `features` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`features`)),
  `active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `plan_id` (`plan_code`,`entity_type`,`period`,`currency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- quota JSON MUST keep $.disk (+ $.desk_disk/$.hub_disk) — disk_limit/disk_free read those keys.
-- stripe_price_id stays NULL here; real test price ids are set by a one-off data step (plan Task E1),
-- NOT in this manifest seed, so a manifest re-run does not clobber them.
-- 2026-07 pricing rebuild. Prices live in Stripe; this seeds only the catalog
-- rows and the quota each plan grants. stripe_price_id stays NULL and is set
-- per environment out-of-band — sandbox and live are separate Stripe accounts,
-- so price ids are never portable between them.
--
--   FREE      $0     — 25 GB,  up to 3 members
--   TEAM      $29/mo — 100 GB, up to 10 members   (entry paid tier, B2B)
--   BUSINESS  $99/mo — 1 TB,   unlimited members  (sales-led, no Stripe price)
--   Yearly = 11 x monthly (one month free): team $319, business $1089.
--   SOVEREIGN is self-hosted and sales-led — not a SaaS entitlement, so absent.
--
-- quota.$.seat is a member CAP, not a purchased quantity, and it COUNTS THE
-- OWNER: free 3, team 10, business 100000
-- (effectively unlimited, but a real number so `if (!quota.seat)` still works).
--
-- TEAM IS FLAT, not per-seat: quota.$.disk is the whole allowance and
-- payment_apply_entitlement must not multiply it by the subscription quantity.
-- The two move together.
--
-- The retired B2C catalog (pro, pro_seat, storage_* and every EUR row) is
-- deactivated on existing DBs by
-- yellow_page/patches/2026-07-24-pricing-usd-team-business.sql; a fresh DB
-- simply never gets those rows.
INSERT IGNORE INTO `plan` (plan_code,entity_type,period,currency,quota,features,active,stripe_price_id) VALUES
 ('free','user','free','usd', JSON_OBJECT('plan','free','disk',25000000000,'desk_disk',25000000000,'hub_disk',25000000000,'seat',3,'organization',0,'history_length',0,'private_hub',1,'share_hub',0,'public_hub',0,'task_views','board,list','meeting_minutes',45), JSON_OBJECT(), 1, NULL),
 ('team','org','month','usd', JSON_OBJECT('plan','team','disk',100000000000,'seat',10,'organization',1,'history_length',30,'private_hub',1,'share_hub',1,'public_hub',0,'task_views','*','meeting_minutes',0), JSON_OBJECT(), 1, NULL),
 ('team','org','year','usd',  JSON_OBJECT('plan','team','disk',100000000000,'seat',10,'organization',1,'history_length',30,'private_hub',1,'share_hub',1,'public_hub',0,'task_views','*','meeting_minutes',0), JSON_OBJECT(), 1, NULL),
 ('business','org','month','usd', JSON_OBJECT('plan','business','disk',1000000000000,'seat',100000,'organization',1,'history_length',365,'task_views','*','meeting_minutes',0), JSON_OBJECT(), 1, NULL),
 ('business','org','year','usd',  JSON_OBJECT('plan','business','disk',1000000000000,'seat',100000,'organization',1,'history_length',365,'task_views','*','meeting_minutes',0), JSON_OBJECT(), 1, NULL);
