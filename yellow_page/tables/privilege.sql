CREATE TABLE `privilege` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `domain_id` int(11) unsigned NOT NULL,
  `privilege` int(4) unsigned DEFAULT 0,
  `is_authoritative` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
