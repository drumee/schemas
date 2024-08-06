CREATE TABLE `contact_assignment` (
  `sys_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `category` enum('role','member') NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `hub_iduid` (`owner_id`,`entity_id`,`category`),
  KEY `owner_id` (`owner_id`),
  KEY `entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
