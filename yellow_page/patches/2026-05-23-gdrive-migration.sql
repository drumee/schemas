-- ============================================================================
-- 2026-05-23 — Google Drive migration support
-- ALTER oauth_accounts: add scope + expires_at (NULL = unknown / legacy)
-- Idempotent: safe to re-apply.
--
-- NOTE: An earlier revision of this patch also CREATEd a `migration_jobs`
-- table. The architecture moved to Bull-only (job state lives in Redis),
-- so the table was dropped via patches/2026-05-25-drop-migration-jobs.sql.
-- ============================================================================

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
