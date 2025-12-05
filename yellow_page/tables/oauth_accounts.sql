-- File: ~/schemas/yellow_page/tables/001_create_oauth_accounts.sql
CREATE TABLE  IF NOT EXISTS `oauth_accounts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Reference to yp.entity.id',
  `provider` enum('google','apple','dropbox') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'OAuth provider name',
  `provider_user_id` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `email` varchar(255) NOT NULL,
  `access_token` text DEFAULT NULL,
  `refresh_token` text DEFAULT NULL,
  `ctime` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (created_at)',
  `mtime` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (updated_at)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_provider_user` (`provider`,`provider_user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_email` (`email`),
  CONSTRAINT `fk_oauth_user_entity` FOREIGN KEY (`user_id`) REFERENCES `entity` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Links Drumee users (entity) to Google/Apple OAuth provider IDs'