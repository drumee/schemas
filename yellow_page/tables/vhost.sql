CREATE TABLE `vhost` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `fqdn` varchar(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `dom_id` int(11) unsigned DEFAULT 1,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `fqdn` (`fqdn`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
