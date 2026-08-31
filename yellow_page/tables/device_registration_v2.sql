CREATE TABLE IF NOT EXISTS `device_registration_v2` (
  `registration_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `registration_kind` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `registration_digest` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `push_token` TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `device_id` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `device_type` VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `state` ENUM('active', 'inactive', 'tombstoned') NOT NULL DEFAULT 'active',
  `binding_version` BIGINT UNSIGNED NOT NULL DEFAULT 1,
  `state_version` BIGINT UNSIGNED NOT NULL DEFAULT 1,
  `expires_at` DATETIME(6) NOT NULL,
  `ctime` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `mtime` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`registration_id`),
  UNIQUE KEY `device_registration_v2_kind_digest` (`registration_kind`, `registration_digest`),
  KEY `device_registration_v2_uid_state_expiry` (`uid`, `state`, `expires_at`, `registration_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
