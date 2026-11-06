-- Email gate on a plain dmz link (a meeting's guest link, room.public_link):
-- "Require email to view" and the "Restrict access to specific emails or
-- domains" allow-list, the same two settings secure_share_token carries.
-- Written by dmz_set_email_gate, read back by dmz_info_next, enforced in
-- server dmz.js login.
ALTER TABLE `dmz_token`
  ADD COLUMN IF NOT EXISTS `require_email` tinyint unsigned NOT NULL DEFAULT 0 AFTER `notify_at`,
  ADD COLUMN IF NOT EXISTS `allowed_emails` json DEFAULT NULL AFTER `require_email`;
