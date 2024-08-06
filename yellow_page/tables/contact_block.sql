CREATE TABLE `contact_block` (
  `sys_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `contact_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `entity` varchar(255) NOT NULL,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `contact_id` (`owner_id`,`contact_id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
