CREATE TABLE `helpdesk` (
  `ord` int(11) unsigned NOT NULL,
  `ln` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `category` varchar(2000) DEFAULT NULL,
  `category_desc` varchar(2000) DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  UNIQUE KEY `ord` (`ord`,`ln`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
