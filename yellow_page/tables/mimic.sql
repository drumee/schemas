CREATE TABLE `mimic` (
  `id` varchar(16) NOT NULL,
  `mimicker` varchar(16) NOT NULL,
  `uid` varchar(16) NOT NULL,
  `status` enum('new','active','reject','endbytime','endbyuser','endbymimic') NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `estimatetime` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`mimicker`,`uid`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
