CREATE TABLE `error` (
  `code` varchar(40) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `level` enum('request','security','critical','system','bug','user') NOT NULL DEFAULT 'user',
  `http_code` int(11) NOT NULL DEFAULT 500,
  PRIMARY KEY (`code`),
  KEY `level` (`level`,`http_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
