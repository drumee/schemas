-- Add is_private_email to oauth_accounts.
-- Apple's id_token carries an `is_private_email` claim that is true when the
-- user picked "Hide My Email" and the `email` is an @privaterelay.appleid.com
-- forwarding address (vs. their real address when they picked "Share My Email").
-- Capturing it lets us detect relay users and keep the stored address synced
-- when Apple rotates the relay (revoke + re-grant issues a new relay, same sub).
ALTER TABLE `oauth_accounts`
  ADD COLUMN IF NOT EXISTS `is_private_email` tinyint(1) NOT NULL DEFAULT 0
  COMMENT 'Apple is_private_email claim: 1 when email is an @privaterelay.appleid.com forwarding address'
  AFTER `email`;
