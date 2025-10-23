DROP TABLE IF EXISTS `push_notification`;
CREATE TABLE `push_notification` (
  `id` INT(11) unsigned NOT NULL,
  `type` VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
  `sent` BOOLEAN,
  PRIMARY KEY (`id`)
);

