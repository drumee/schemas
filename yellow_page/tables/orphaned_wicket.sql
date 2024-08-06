CREATE TABLE `orphaned_wicket` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `owner_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `db_name` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `db_name` (`db_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
