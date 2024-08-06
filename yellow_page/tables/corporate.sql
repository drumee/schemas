CREATE TABLE `corporate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) NOT NULL,
  `entity_id` varchar(16) NOT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `status` enum('active','invite','delete') DEFAULT 'invite',
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`owner_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
