-- ============================================================================
-- 2026-05-23 — Google Drive migration support
-- 1. ALTER oauth_accounts: add scope + expires_at (NULL = unknown / legacy)
-- 2. CREATE migration_jobs: per-user, per-provider job tracking
-- Idempotent: safe to re-apply.
-- ============================================================================

-- 1. ALTER oauth_accounts -----------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS `_add_col_if_missing` $$
CREATE PROCEDURE `_add_col_if_missing`(
  IN tbl VARCHAR(64),
  IN col VARCHAR(64),
  IN ddl VARCHAR(512)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = tbl
      AND column_name = col
  ) THEN
    SET @s = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN ', ddl);
    PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END IF;
END $$

DELIMITER ;

CALL _add_col_if_missing('oauth_accounts', 'scope',
  '`scope` VARCHAR(512) DEFAULT NULL COMMENT ''Space-separated OAuth scope list'' AFTER `refresh_token`');

CALL _add_col_if_missing('oauth_accounts', 'expires_at',
  '`expires_at` INT(10) UNSIGNED DEFAULT NULL COMMENT ''Unix ts of access_token expiry'' AFTER `scope`');

DROP PROCEDURE IF EXISTS `_add_col_if_missing`;

-- 2. CREATE migration_jobs ----------------------------------------------------

CREATE TABLE IF NOT EXISTS `migration_jobs` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- Match `oauth_accounts.user_id` (utf8mb4_general_ci) — that FK to
  -- entity.id already works on stage, so this is the proven-good
  -- collation for entity-id columns regardless of what entity.sql says.
  `user_id`               VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `provider`              ENUM('google','dropbox','onedrive') NOT NULL,
  `source_folder_id`      VARCHAR(255) NOT NULL DEFAULT 'root',
  `dest_hub_id`           VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `dest_nid`              VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status`                ENUM('queued','running','done','failed','cancelled') NOT NULL DEFAULT 'queued',
  `conflict_policy`       ENUM('skip','overwrite','rename') NOT NULL DEFAULT 'skip',
  `include_shared_drives` TINYINT(1) NOT NULL DEFAULT 0,
  `total_files`           INT UNSIGNED NOT NULL DEFAULT 0,
  `processed_files`       INT UNSIGNED NOT NULL DEFAULT 0,
  `total_folders`         INT UNSIGNED NOT NULL DEFAULT 0,
  `errors_json`           MEDIUMTEXT NULL,
  `started_at`            INT UNSIGNED NULL,
  `finished_at`           INT UNSIGNED NULL,
  `ctime`                 INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_status`     (`user_id`, `status`),
  KEY `idx_provider_user`   (`provider`, `user_id`),
  CONSTRAINT `fk_migration_user` FOREIGN KEY (`user_id`)
    REFERENCES `entity` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
