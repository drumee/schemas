CREATE TABLE IF NOT EXISTS `notification_activity_bookmark_row` (
  `bookmark_key` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `bucket` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  `row_time` INT UNSIGNED NOT NULL DEFAULT 0,
  `payload` MEDIUMTEXT NOT NULL,
  `ctime` INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (`bookmark_key`),
  KEY `idx_bucket_time` (`bucket`, `row_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
