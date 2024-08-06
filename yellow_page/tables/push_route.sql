CREATE TABLE `push_route` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `address` varchar(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `path` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `address` (`address`),
  UNIQUE KEY `path` (`path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
