DROP TABLE IF EXISTS `package`;
CREATE TABLE `user` (
  `name` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `version` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `arch` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `platform` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `path` varchar(128) NOT NULL DEFAULT '',
  `metadata` json,
  PRIMARY KEY `id` (`name`,`version`, `arch, `platform`),
  UNIQUE KEY `path` (`path`)
) ENGINE=InnoDB  ;
