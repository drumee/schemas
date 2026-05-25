-- Purpose: Track migration status for all hub databases

DROP TABLE IF EXISTS `migration_log`;

CREATE TABLE IF NOT EXISTS `migration_log` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `hub_id` VARCHAR(16) NOT NULL COMMENT 'Hub entity ID',
  `db_name` VARCHAR(64) NOT NULL COMMENT 'Hub database name',
  `migration_name` VARCHAR(128) NOT NULL COMMENT 'Migration identifier',
  `status` ENUM('success', 'failed', 'skipped') NOT NULL DEFAULT 'success',
  `error_msg` TEXT DEFAULT NULL COMMENT 'Error message if failed',
  `executed_at` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'UNIX timestamp of execution',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hub_migration` (`hub_id`, `migration_name`),
  KEY `idx_migration_name` (`migration_name`),
  KEY `idx_status` (`status`),
  KEY `idx_executed_at` (`executed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Migration execution log for hub databases';