DROP TABLE IF EXISTS `authn`;

CREATE TABLE `authn` (
  `token` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `type` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci GENERATED ALWAYS AS (json_value(`value`,'$.type')) VIRTUAL,
  `id` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci GENERATED ALWAYS AS (json_value(`value`,'$.id')) VIRTUAL,
  `host` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci GENERATED ALWAYS AS (json_value(`value`,'$.host')) VIRTUAL,
  `value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`value`)),
  PRIMARY KEY (`token`)
) ;

CREATE TABLE `asset` (
  `name` varchar(64) CHARACTER SET ascii,
  `host` varchar(128) CHARACTER SET ascii,
  `srcdir` varchar(1000) CHARACTER SET ascii,
  PRIMARY KEY (`name`)
) ;