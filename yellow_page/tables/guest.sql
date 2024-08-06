CREATE TABLE `guest` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `email` varchar(512) NOT NULL,
  `firstname` varchar(128) DEFAULT '',
  `lastname` varchar(128) DEFAULT '',
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `firstname` (`firstname`),
  KEY `lastname` (`lastname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
