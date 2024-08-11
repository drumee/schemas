DROP TABLE IF EXISTS `form`;
CREATE TABLE `form` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `domain_name` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.domain_name')) VIRTUAL,
  `data_dir` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.data_dir')) VIRTUAL,
  `db_dir` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.db_dir')) VIRTUAL,
  `wallpaper_dir` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.wallpaper_dir')) VIRTUAL,
  `import_dir` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.import_dir')) VIRTUAL,
  `export_dir` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.export_dir')) VIRTUAL,
  `own_ssl`  tinyint GENERATED ALWAYS AS (json_value(`profile`,'$.own_ssl')) VIRTUAL,
  `acme_ssl` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.acme_ssl')) VIRTUAL,
  `acme_email_account` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.acme_email_account')) VIRTUAL,
  `acme_dns` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.acme_dns')) VIRTUAL,
  `profile` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`profile`)),
  PRIMARY KEY `id` (`id`)
 ) ENGINE=InnoDB ;



DROP TABLE IF EXISTS `customer`;
CREATE TABLE `customer` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `user_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `form_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `company_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY `id` (`id`)
) ENGINE=InnoDB ;



DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `fingerprint` varchar(128) NOT NULL DEFAULT '',
  `firstname` varchar(300) GENERATED ALWAYS AS (json_value(`profile`,'$.firstname')) VIRTUAL,
  `lastname` varchar(300) GENERATED ALWAYS AS (json_value(`profile`,'$.lastname')) VIRTUAL,
  `avatar` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.avatar')) VIRTUAL,
  `lang` varchar(30) GENERATED ALWAYS AS (json_value(`profile`,'$.lang')) VIRTUAL,
  `email` varchar(512) GENERATED ALWAYS AS (json_value(`profile`,'$.email')) VIRTUAL,
  `role` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.role')) VIRTUAL,
  `otp` varchar(50) GENERATED ALWAYS AS (IFNULL(convert(json_unquote(json_extract(`profile`,'$.otp')) using utf8mb4),'0')) VIRTUAL,
  `profile` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`profile`)),
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB  ;


DROP TABLE IF EXISTS `licence`;
CREATE TABLE `licence` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `key` varchar(128),
  `customer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `start` INTEGER(11) UNSIGNED,
  `end` INTEGER(11) UNSIGNED,
  `status` enum('pending','active','expired','revoked', 'exception'),
  PRIMARY KEY `id` (`id`)
) ENGINE=InnoDB ;


DROP TABLE IF EXISTS `company`;
CREATE TABLE `company` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `poc_id` varchar(16) GENERATED ALWAYS AS (json_value(`profile`,'$.poc_id')) VIRTUAL,
  `name` varchar(128) GENERATED ALWAYS AS (json_value(`profile`,'$.company_name')) VIRTUAL,
  `domain_name` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.domain_name')) VIRTUAL,
  `vat_number` varchar(128) GENERATED ALWAYS AS (json_value(`profile`,'$.vat_number')) VIRTUAL,
  `avatar` varchar(1000) GENERATED ALWAYS AS (json_value(`profile`,'$.avatar')) VIRTUAL,
  `profile` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`profile`)),
  PRIMARY KEY `id` (`id`)
) ENGINE=InnoDB ;