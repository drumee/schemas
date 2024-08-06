CREATE TABLE `profile` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `drumate_id` varbinary(16) NOT NULL,
  `photo` varbinary(16) NOT NULL,
  `area` varchar(10) DEFAULT 'public',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `public` (`photo`),
  KEY `drumate_id` (`drumate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
