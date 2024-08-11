DROP TABLE IF EXISTS `enterprise`;
CREATE TABLE `enterprise` (
  `id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `legal_id` VARCHAR(120) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `bu_id` VARCHAR(120) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `vat_id` VARCHAR(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `legal_name` VARCHAR(128),
  `activity_id` VARCHAR(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `category` VARCHAR(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `commercial_name` VARCHAR(128),
  `date_of_start` INT(11),
  `date_of_end` INT(11),
  `country_code` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `poc_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `location` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`location`)),
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY `bu_id` (`bu_id`),
  INDEX `legal_name` (`legal_name`),
  INDEX `category`  (`category`),
  FULLTEXT(`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;