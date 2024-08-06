CREATE TABLE `avatar` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `drumate_id` varbinary(16) NOT NULL,
  `location` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `drumate_id` (`drumate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
