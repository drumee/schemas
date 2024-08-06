CREATE TABLE `validation_code` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `action` enum('delete_drumate_account','forgot_password') DEFAULT NULL,
  `code` varchar(255) NOT NULL,
  `expiry_time` int(11) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
