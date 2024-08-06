CREATE TABLE `subscription_new` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `subscription_id` varchar(30) DEFAULT NULL,
  `customer_id` varchar(30) DEFAULT NULL,
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `period` enum('free','month','year') DEFAULT 'free',
  `recurring` int(11) DEFAULT 0,
  `price` float DEFAULT 0,
  `offer_price` float DEFAULT NULL,
  `status` enum('incomplete','incomplete_expired','trialing','active','past_due','canceled','unpaid') DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
