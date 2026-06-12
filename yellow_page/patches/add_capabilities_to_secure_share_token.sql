ALTER TABLE `secure_share_token`
  ADD COLUMN IF NOT EXISTS `capabilities` json DEFAULT NULL AFTER `permission_level`;
