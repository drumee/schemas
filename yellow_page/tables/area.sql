CREATE TABLE `area` (
  `id` varchar(16) NOT NULL,
  `owner_id` varchar(16) NOT NULL,
  `level` enum('public','restricted','private','personal','system','dummy') NOT NULL,
  PRIMARY KEY (`id`),
  KEY `level` (`level`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
