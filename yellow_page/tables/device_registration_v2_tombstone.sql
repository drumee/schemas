CREATE TABLE IF NOT EXISTS `device_registration_v2_tombstone` (
  `tombstone_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `registration_id` BIGINT UNSIGNED NOT NULL,
  `uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `binding_version` BIGINT UNSIGNED NOT NULL,
  `state_version` BIGINT UNSIGNED NOT NULL,
  `result_binding_version` BIGINT UNSIGNED NOT NULL,
  `result_state_version` BIGINT UNSIGNED NOT NULL,
  `reason` ENUM('unregistered', 'rebound', 'invalidated', 'reactivated', 'token_rotated') NOT NULL,
  `ctime` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`tombstone_id`),
  UNIQUE KEY `device_registration_v2_tombstone_transition` (
    `registration_id`, `uid`, `binding_version`, `state_version`, `reason`
  ),
  KEY `device_registration_v2_tombstone_uid` (`uid`, `ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
