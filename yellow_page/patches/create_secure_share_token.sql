-- Patch: add secure_share_token table for per-email unique secure share links.
-- Safe to run multiple times (CREATE TABLE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `secure_share_token` (
  `sys_id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id`                 varchar(80)      NOT NULL,
  `hub_id`             varchar(16)      CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `node_id`            varchar(16)      CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `creator_id`         varchar(16)      CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `recipient_email`    varchar(512)     NOT NULL,
  `domain_restriction` varchar(255)     DEFAULT NULL,
  `expiry_time`        int(11)          NOT NULL DEFAULT 0,
  `revoked_at`         int(11)          DEFAULT NULL,
  `access_count`       int(11) unsigned NOT NULL DEFAULT 0,
  `last_accessed`      int(11)          DEFAULT NULL,
  `ctime`              int(11)          NOT NULL DEFAULT unix_timestamp(),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id`            (`id`),
  KEY        `idx_hub_node`  (`hub_id`, `node_id`),
  KEY        `idx_creator`   (`creator_id`),
  KEY        `idx_recipient` (`recipient_email`(191)),
  KEY        `idx_ctime`     (`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
