ALTER TABLE `secure_share_token`
  ADD COLUMN IF NOT EXISTS `denied_emails` json DEFAULT NULL AFTER `allowed_emails`;
