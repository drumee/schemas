CREATE TABLE `organisation_entity` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `org_id` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `old_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `temp_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `is_checked` int(11) DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `org_id` (`org_id`),
  UNIQUE KEY `old_id` (`old_id`),
  UNIQUE KEY `old_idorg_id` (`org_id`,`old_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
