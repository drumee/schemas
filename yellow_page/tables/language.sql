CREATE TABLE `language` (
  `code` varchar(8) NOT NULL,
  `lcid` varchar(16) NOT NULL,
  `locale_en` varchar(128) NOT NULL,
  `locale` varchar(128) NOT NULL,
  `flag_image` varchar(200) DEFAULT NULL,
  `state` enum('active','deleted') NOT NULL DEFAULT 'deleted',
  `comment` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
