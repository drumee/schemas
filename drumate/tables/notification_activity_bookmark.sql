CREATE TABLE IF NOT EXISTS `notification_activity_bookmark` (
  `bookmark_key` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `ctime` INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (`bookmark_key`),
  KEY `idx_bookmark_time` (`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
