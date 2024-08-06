CREATE TABLE `renewal_failed` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `invoice_id` varchar(30) DEFAULT NULL,
  `subscription_id` varchar(30) DEFAULT NULL,
  `payment_intent_id` varchar(30) DEFAULT NULL,
  `product` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `period` enum('free','month','year') DEFAULT 'free',
  `recurring` int(11) DEFAULT 0,
  `price` float DEFAULT 0,
  `offer_price` float DEFAULT NULL,
  `renewal_amount` int(11) unsigned NOT NULL,
  `url` varchar(300) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
