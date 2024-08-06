CREATE TABLE `asset` (
  `name` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `host` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `srcdir` varchar(1000) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
