CREATE TABLE `map_role` (
  `sys_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `role_id` int(11) NOT NULL,
  `org_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `name` (`org_id`,`role_id`,`uid`),
  KEY `idx_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
