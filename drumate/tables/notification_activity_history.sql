CREATE TABLE IF NOT EXISTS `notification_activity_history` (
  `history_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `notification_key` VARCHAR(255) NOT NULL,
  `hub_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  `last_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `ctime` INT UNSIGNED NOT NULL,
  `read_at` INT UNSIGNED NOT NULL,
  `hidden_at` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  UNIQUE KEY `uk_notification_identity` (`category`, `notification_key`, `hub_id`, `last_id`),
  KEY `idx_visible_time` (`hidden_at`, `ctime`, `history_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
