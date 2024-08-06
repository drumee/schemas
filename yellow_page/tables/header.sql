CREATE TABLE `header` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `language` varchar(50) NOT NULL,
  `icon` varchar(1024) DEFAULT NULL,
  `title` varchar(500) NOT NULL,
  `keywords` varchar(500) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
