CREATE TABLE IF NOT EXISTS `payment` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `invoice_id` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `payer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `plan_name` varchar(30) DEFAULT NULL,
  `metadata` JSON,
  `ctime` int(11) unsigned NOT NULL,
  `mtime` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `invoice_id` (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
