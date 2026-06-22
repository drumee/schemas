-- yp.plan is a CATALOG (no customer data) — safe to DROP+CREATE. Price truth = Stripe;
-- this table stores stripe_price_id per (plan_code, entity_type, period, currency) + the quota a plan grants.
DROP TABLE IF EXISTS `plan`;
CREATE TABLE IF NOT EXISTS `plan` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'free',
  `entity_type` enum('user','org') NOT NULL DEFAULT 'user',
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
REPLACE INTO `plan` (plan_code,entity_type,period,currency,quota,features,active,stripe_price_id) VALUES
 ('free','user','free','eur', JSON_OBJECT('plan','free','disk',20000000000,'desk_disk',20000000000,'hub_disk',20000000000,'seat',0,'organization',0,'history_length',0), JSON_OBJECT(), 1, NULL),
 ('pro','user','month','eur', JSON_OBJECT('plan','pro','disk',50000000000,'desk_disk',50000000000,'hub_disk',50000000000,'seat',5,'organization',1,'history_length',7), JSON_OBJECT(), 1, NULL),
 ('pro','user','year','eur',  JSON_OBJECT('plan','pro','disk',50000000000,'desk_disk',50000000000,'hub_disk',50000000000,'seat',5,'organization',1,'history_length',7), JSON_OBJECT(), 1, NULL);
