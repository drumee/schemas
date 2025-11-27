-- File: schemas/drumate/tables/mfs_ack.sql
-- Purpose: Track last read changelog ID per user for notification acknowledgement

CREATE TABLE IF NOT EXISTS `mfs_ack` (
  `user_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `last_read_id` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest mfs_changelog.id that user has read',
  `mtime` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Last update timestamp',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
COMMENT='User acknowledgement of MFS changelog events - stores last read ID';