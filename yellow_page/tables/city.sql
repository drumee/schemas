CREATE TABLE `city` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cc_iso` varchar(2) DEFAULT NULL,
  `name_ascii` varchar(100) DEFAULT NULL,
  `name_utf8` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `lat` int(8) DEFAULT NULL,
  `lng` int(8) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name_ascii` (`name_ascii`),
  FULLTEXT KEY `name_utf8` (`name_utf8`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
