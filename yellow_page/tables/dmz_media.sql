CREATE TABLE `dmz_media` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
