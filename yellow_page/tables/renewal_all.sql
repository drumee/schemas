CREATE TABLE `renewal_all` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `payment_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `package` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'basic',
  `cycle` enum('no','monthly','yearly','company','other') DEFAULT 'no',
  `mode` enum('free','pay','company','other') DEFAULT 'free',
  `stime` int(11) unsigned NOT NULL,
  `etime` int(11) unsigned NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `payment_id` (`payment_id`),
  UNIQUE KEY `payment_id_entity_id` (`payment_id`,`entity_id`,`stime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
