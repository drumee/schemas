CREATE TABLE `pulic_key` (
  `domain` varchar(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `key` varchar(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `hash` varchar(512) GENERATED ALWAYS AS (sha2(`key`,512)) VIRTUAL,
  PRIMARY KEY (`domain`),
  UNIQUE KEY `hash` (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
