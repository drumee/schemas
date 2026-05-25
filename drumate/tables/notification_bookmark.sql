CREATE TABLE IF NOT EXISTS `notification_bookmark` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `message_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `hub_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime` INT(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uid_message` (`uid`, `message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;