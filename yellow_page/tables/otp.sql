CREATE TABLE `otp` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) NOT NULL,
  `secret` varchar(64) NOT NULL,
  `code` int(11) DEFAULT NULL,
  `ctime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `secret` (`secret`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
