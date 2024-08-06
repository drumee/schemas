CREATE TABLE `job_credential` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `app_key` varchar(100) NOT NULL,
  `customer_key` varchar(100) NOT NULL,
  `job_id` varchar(100) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `job_id` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
