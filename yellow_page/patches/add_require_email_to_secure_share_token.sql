ALTER TABLE `secure_share_token`
  ADD COLUMN IF NOT EXISTS `require_email` tinyint unsigned NOT NULL DEFAULT 0 AFTER `allowed_emails`;
