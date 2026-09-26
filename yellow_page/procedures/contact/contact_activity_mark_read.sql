-- File: schemas/yellow_page/procedures/contact/contact_activity_mark_read.sql
-- Purpose: Mark ONE contact_activity row read for its recipient — dismissed_at
-- only, the row stays in Activity history.
--
-- contact_activity_dismiss also stamps hidden_at, which is the explicit
-- "remove from Activity history" marker (see
-- yellow_page/patches/add-contact-activity-hidden-at.sql and the README), and
-- mobile relies on it meaning removal. The web panel used it to record a READ,
-- so opening a task / meeting / invitation notification made it vanish from the
-- Unread OFF list. This is the read-only counterpart, the contact equivalent of
-- mfs_dismiss_activity; removal stays with contact_activity_dismiss /
-- contact_activity_delete.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_activity_mark_read`$
CREATE PROCEDURE `contact_activity_mark_read`(
  IN _user_id VARCHAR(16),
  IN _activity_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _mtime INT(11) UNSIGNED;
  SELECT UNIX_TIMESTAMP() INTO _mtime;

  UPDATE contact_activity
     SET dismissed_at = _mtime
   WHERE id = _activity_id
     AND target_uid = _user_id
     AND dismissed_at IS NULL;

  SELECT 'ok' AS status, _activity_id AS activity_id, _mtime AS dismissed_at;
END$

DELIMITER ;
