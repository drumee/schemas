ALTER TABLE `secure_share_token`
  ADD COLUMN `permission_level` ENUM('can_view','can_download','can_chat','can_edit')
    NOT NULL DEFAULT 'can_view' AFTER `creator_id`,
  ADD COLUMN `allowed_emails` JSON DEFAULT NULL AFTER `domain_restriction`,
  ADD COLUMN `failed_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  ADD COLUMN `locked_at` INT DEFAULT NULL,
  MODIFY COLUMN `recipient_email` VARCHAR(512) DEFAULT NULL;

UPDATE `secure_share_token`
  SET `allowed_emails` = JSON_ARRAY(`recipient_email`)
  WHERE `recipient_email` IS NOT NULL AND `allowed_emails` IS NULL;
