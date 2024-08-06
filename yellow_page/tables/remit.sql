CREATE TABLE `remit` (
  `method` varchar(255) NOT NULL,
  `level` bit(3) NOT NULL,
  UNIQUE KEY `method` (`method`),
  KEY `module` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
