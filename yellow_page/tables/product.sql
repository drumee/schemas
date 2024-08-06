CREATE TABLE `product` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `product` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `period` enum('free','month','year') DEFAULT 'free',
  `recurring` int(11) DEFAULT 0,
  `price` float DEFAULT 0,
  `offer_price` float DEFAULT NULL,
  `pay_mode` enum('free','pay','company','other') DEFAULT 'free',
  `is_active` int(1) DEFAULT 1,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
