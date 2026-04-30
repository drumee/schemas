-- File: schemas/drumate/tables/mfs_dismissed.sql
-- Per-user table tracking dismissed activity changelog entries

CREATE TABLE IF NOT EXISTS `mfs_dismissed` (
  `changelog_id` INT(11) UNSIGNED NOT NULL,
  `user_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
  `mtime` INT(11) UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (`changelog_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
