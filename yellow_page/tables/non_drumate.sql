CREATE TABLE `non_drumate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `email` varchar(500) NOT NULL,
  `firstname` varchar(200) DEFAULT NULL,
  `lastname` varchar(200) DEFAULT NULL,
  `mobile` varchar(40) DEFAULT NULL,
  `extra` mediumtext DEFAULT NULL,
  `privilege` varchar(50) DEFAULT NULL,
  `token` varchar(255) NOT NULL,
  `action` enum('add_contributor','add_contact','share_media') NOT NULL,
  `entity_id` varchar(100) NOT NULL,
  `item_id` varchar(100) NOT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `email` (`email`,`action`,`entity_id`,`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
