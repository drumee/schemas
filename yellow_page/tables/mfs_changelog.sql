DROP TABLE IF EXISTS `mfs_changelog`;
CREATE TABLE `mfs_changelog` (
  `id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` int(11) unsigned NOT NULL,
  `uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci,
  `hub_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci,
  `event` VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
  src JSON,
  dest JSON DEFAULT '{}',
  PRIMARY KEY (`id`)
);

