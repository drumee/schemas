-- /** 
-- Contact may be the same as user.
-- Contact is on of users
-- */
-- DROP TABLE IF EXISTS `customer`;
-- CREATE TABLE `customer` (
--   `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
--   `user_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
--   `form_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
--   `company_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
--   PRIMARY KEY `id` (`id`)
-- ) ENGINE=InnoDB ;

DROP TABLE IF EXISTS `customer`;
CREATE TABLE `customer` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime` int(11) DEFAULT NULL,
  `firstname` varchar(128) NOT NULL,
  `lastname` varchar(128) NOT NULL,
  `email` varchar(128) NOT NULL,
  `phone_area` INTEGER,
  `phone_number` INTEGER,
  `fullname` varchar(128) GENERATED ALWAYS AS (if(concat(ifnull(`firstname`,''),' ',convert(ifnull(`lastname`,'') using utf8mb4)) = ' ',convert(`email` using utf8mb4),concat(ifnull(`firstname`,''),' ',convert(ifnull(`lastname`,'') using utf8mb4)))) VIRTUAL,
  `avatar` varchar(512) DEFAULT NULL,
  `bu_id` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `reseller_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `location` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`location`)),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
