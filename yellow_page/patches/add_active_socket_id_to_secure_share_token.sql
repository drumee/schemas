-- Patch: add active_socket_id to secure_share_token so revoke can target the
-- recipient's WebSocket socket directly rather than relying on entity_sockets().
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS, MariaDB 10.3+).

ALTER TABLE `secure_share_token`
  ADD COLUMN IF NOT EXISTS `active_socket_id` VARCHAR(32) DEFAULT NULL AFTER `password_hash`;
