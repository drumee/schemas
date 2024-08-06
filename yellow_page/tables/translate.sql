CREATE TABLE `translate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(40) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `key_code` varchar(40) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `lang` varchar(40) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `content` text DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `code` (`code`,`lang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
