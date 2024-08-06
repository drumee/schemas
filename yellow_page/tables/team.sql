CREATE TABLE `team` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `firstname` varchar(80) NOT NULL,
  `lastname` varchar(80) NOT NULL,
  `domain` enum('tech','design','management','qos','marketing','sell') NOT NULL,
  `priority` tinyint(4) NOT NULL,
  `email` varchar(255) NOT NULL,
  `mobile` varchar(80) NOT NULL,
  KEY `priority` (`priority`),
  KEY `name` (`firstname`,`lastname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
