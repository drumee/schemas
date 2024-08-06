CREATE TABLE `country` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cc_iso` varchar(3) NOT NULL,
  `tld` varchar(3) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `fr` varchar(200) NOT NULL,
  `en` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tld` (`tld`),
  FULLTEXT KEY `lang` (`fr`,`en`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
