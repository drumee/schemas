CREATE TABLE IF NOT EXISTS `workspace_invitation` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `token` VARCHAR(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `inviter_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `hub_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `privilege` TINYINT(4) NOT NULL DEFAULT 7,
  `status` ENUM('pending','accepted','expired') NOT NULL DEFAULT 'pending',
  `ctime` INT(11) UNSIGNED NOT NULL,
  `etime` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hub` (`token`, `hub_id`),
  KEY `idx_email` (`email`),
  KEY `idx_inviter` (`inviter_id`),
  KEY `idx_status` (`status`),
  KEY `idx_etime` (`etime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;