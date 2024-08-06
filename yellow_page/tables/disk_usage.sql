CREATE TABLE `disk_usage` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) NOT NULL,
  `size` float DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `hub_id` (`hub_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
