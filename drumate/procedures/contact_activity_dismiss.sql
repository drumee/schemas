-- File: schemas/drumate/procedures/contact_activity_dismiss.sql
-- Purpose: Hide a single contact_activity row from the recipient's
-- activity feed without losing the underlying event row.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_activity_dismiss`$

CREATE PROCEDURE `contact_activity_dismiss`(
  IN _user_id VARCHAR(16),
  IN _activity_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _mtime INT(11) UNSIGNED;
  SELECT UNIX_TIMESTAMP() INTO _mtime;

  UPDATE yp.contact_activity
     SET dismissed_at = _mtime
   WHERE id = _activity_id
     AND target_uid = _user_id
     AND dismissed_at IS NULL;

  SELECT 'ok' AS status, _activity_id AS activity_id, _mtime AS dismissed_at;
END$

DELIMITER ;
