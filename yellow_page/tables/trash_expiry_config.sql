-- Purpose: System-wide trash expiry configuration

DROP TABLE IF EXISTS `trash_expiry_config`;

CREATE TABLE IF NOT EXISTS `trash_expiry_config` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `expiry_days` INT(11) UNSIGNED NOT NULL DEFAULT 30 COMMENT 'Number of days before auto-delete (1-365)',
  `auto_delete_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=disabled, 1=enabled',
  `last_run_time` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'UNIX timestamp of last worker run',
  `ctime` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Creation time',
  `mtime` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Last modification time',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='System-wide trash expiry settings';

-- Insert default configuration
INSERT INTO `trash_expiry_config` 
(`id`, `expiry_days`, `auto_delete_enabled`, `last_run_time`, `ctime`, `mtime`) 
VALUES 
(1, 30, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE 
  `mtime` = UNIX_TIMESTAMP();