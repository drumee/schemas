CREATE TABLE `extention` (
  `key` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
  `extension` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'bin',
  `category` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'other',
  `mimetype` varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'unknown',
  `capability` varchar(8) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '---',
  `description` varchar(512) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '*',
  KEY `category` (`category`,`mimetype`,`capability`),
  FULLTEXT KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
