CREATE TABLE `homework` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `home_id` varchar(16) NOT NULL,
  `work_id` varchar(16) NOT NULL,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`home_id`,`work_id`),
  UNIQUE KEY `home_id` (`home_id`),
  KEY `work_id` (`work_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
