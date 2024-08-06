CREATE TABLE `user_var` (
  `name` varchar(40) NOT NULL,
  `value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`value`)),
  PRIMARY KEY (`name`),
  FULLTEXT KEY `value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
