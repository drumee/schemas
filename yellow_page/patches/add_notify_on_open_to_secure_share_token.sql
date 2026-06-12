ALTER TABLE `secure_share_token`
  ADD COLUMN IF NOT EXISTS `notify_on_open` tinyint unsigned NOT NULL DEFAULT 1 AFTER `require_email`;
