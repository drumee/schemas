CREATE TABLE `subscription_history` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `payment_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `subscription_id` varchar(30) DEFAULT NULL,
  `payment_intent_id` varchar(30) DEFAULT NULL,
  `product_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `product` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `period` enum('free','month','year') DEFAULT 'free',
  `recurring` int(11) DEFAULT 0,
  `price` float DEFAULT 0,
  `offer_price` float DEFAULT NULL,
  `renewal_amount` int(11) unsigned NOT NULL,
  `stime` int(11) unsigned NOT NULL,
  `etime` int(11) unsigned NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `payment_id` (`subscription_id`,`payment_intent_id`,`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
