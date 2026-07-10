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
INSERT IGNORE INTO `plan` (plan_code,entity_type,period,currency,quota,features,active,stripe_price_id) VALUES
 ('free','user','free','eur', JSON_OBJECT('plan','free','disk',20000000000,'desk_disk',20000000000,'hub_disk',20000000000,'seat',0,'organization',0,'history_length',0), JSON_OBJECT(), 1, NULL),
 ('pro','user','month','eur', JSON_OBJECT('plan','pro','disk',50000000000,'desk_disk',50000000000,'hub_disk',50000000000,'seat',5,'organization',1,'history_length',7), JSON_OBJECT(), 1, NULL),
 ('pro','user','year','eur',  JSON_OBJECT('plan','pro','disk',50000000000,'desk_disk',50000000000,'hub_disk',50000000000,'seat',5,'organization',1,'history_length',7), JSON_OBJECT(), 1, NULL),
 -- P3 org/team: PER-SEAT. quota.disk here is the PER-SEAT allowance;
 -- payment_apply_entitlement multiplies it by the seat quantity. desk_disk/
 -- hub_disk are omitted so disk_limit's IFNULL falls back to the scaled disk.
 ('team','org','month','eur', JSON_OBJECT('plan','team','disk',50000000000,'seat',0,'organization',1,'history_length',30), JSON_OBJECT(), 1, NULL),
 ('team','org','year','eur',  JSON_OBJECT('plan','team','disk',50000000000,'seat',0,'organization',1,'history_length',30), JSON_OBJECT(), 1, NULL),
 -- P4 storage add-ons (entity_type='addon'): a recurring line-item on the
 -- subscription; the reducer sums their $.disk into the entitlement's extra_disk.
 -- One price per period (Stripe requires add-on interval = subscription interval).
 ('storage_100','addon','month','eur',  JSON_OBJECT('plan','storage_100','disk',100000000000), JSON_OBJECT(), 1, NULL),
 ('storage_100','addon','year','eur',   JSON_OBJECT('plan','storage_100','disk',100000000000), JSON_OBJECT(), 1, NULL),
 ('storage_500','addon','month','eur',  JSON_OBJECT('plan','storage_500','disk',500000000000), JSON_OBJECT(), 1, NULL),
 ('storage_500','addon','year','eur',   JSON_OBJECT('plan','storage_500','disk',500000000000), JSON_OBJECT(), 1, NULL),
 ('storage_1000','addon','month','eur', JSON_OBJECT('plan','storage_1000','disk',1000000000000), JSON_OBJECT(), 1, NULL),
 ('storage_1000','addon','year','eur',  JSON_OBJECT('plan','storage_1000','disk',1000000000000), JSON_OBJECT(), 1, NULL),
 -- C1 Pro per-seat: Pro includes quota.$.seat seats (5); extra seats are a
 -- recurring add-on line item (quantity = extra seats). $.seat=1 marks one
 -- seat per unit; no $.disk — seats don't add storage on Pro.
 ('pro_seat','addon','month','eur', JSON_OBJECT('plan','pro_seat','seat',1), JSON_OBJECT(), 1, NULL),
 ('pro_seat','addon','year','eur',  JSON_OBJECT('plan','pro_seat','seat',1), JSON_OBJECT(), 1, NULL);
