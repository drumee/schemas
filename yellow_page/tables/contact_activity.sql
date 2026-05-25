-- File: schemas/yellow_page/tables/contact_activity.sql
-- Purpose: Store contact activity events (invitations, accepts, refuses)

CREATE TABLE IF NOT EXISTS `contact_activity` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `timestamp` INT(11) UNSIGNED NOT NULL,
  `uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'User who triggered the action',
  `target_uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'User who receives the action',
  `event` VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'Event type: invite_sent, invite_received, invite_accepted, invite_refused',
  `data` JSON DEFAULT NULL COMMENT 'Additional event data (email, message, etc)',
  `dismissed_at` INT(11) UNSIGNED DEFAULT NULL COMMENT 'When the recipient dismissed this row from the activity panel',
  PRIMARY KEY (`id`),
  INDEX `idx_uid` (`uid`),
  INDEX `idx_target_uid` (`target_uid`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_event` (`event`),
  INDEX `idx_dismissed_at` (`dismissed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;