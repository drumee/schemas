CREATE TABLE `verification` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `drumate_id` varbinary(16) NOT NULL,
  `token` varchar(255) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
