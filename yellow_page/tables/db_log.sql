CREATE TABLE `db_log` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log` varchar(5000) DEFAULT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
