-- File: schemas/drumate/procedures/mfs_dismiss_activity.sql

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_dismiss_activity`$

CREATE PROCEDURE `mfs_dismiss_activity`(
  IN _user_id VARCHAR(16),
  IN _changelog_id INT(11)
)
BEGIN
  INSERT IGNORE INTO mfs_dismissed (changelog_id, user_id, mtime)
  VALUES (_changelog_id, _user_id, UNIX_TIMESTAMP());

  SELECT 'ok' AS status, _changelog_id AS changelog_id;
END$

DELIMITER ;
