-- Patch: add password_hash column to secure_share_token.
-- Allows senders to optionally protect a share link with a bcrypt/pbkdf2 password.
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS is idempotent in MariaDB 10.3+).

ALTER TABLE `secure_share_token`
  ADD COLUMN IF NOT EXISTS `password_hash` VARCHAR(255) DEFAULT NULL AFTER `domain_restriction`;
