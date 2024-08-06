CREATE TABLE `dmz_user` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `email` varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `name` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
