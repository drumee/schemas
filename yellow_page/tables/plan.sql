CREATE TABLE `plan` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'basic',
  `display_name` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'Basic',
  `cycle` enum('no','monthly','yearly','company','other') DEFAULT 'no',
  `duration` int(11) DEFAULT 0,
  `amount` float DEFAULT 0,
  `offer_amount` float DEFAULT NULL,
  `mode` enum('free','pay','company','other') DEFAULT 'free',
  `state` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'active',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `plan` (`plan`,`cycle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
