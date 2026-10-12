-- File: schemas/yellow_page/procedures/contact/contact_unread_mark_read.sql
-- Purpose: Mark as all read for a notification tab: every unread row of ONE
-- contact_activity event in a single statement. Read, not removed - it sets
-- dismissed_at only, exactly like contact_activity_mark_read per row, so the
-- rows stay in Activity history. Replaces looping over the 50-row
-- contact_*_unread lists, which cleared 100 task rows per click and left the
-- badge back at 100 for a user with hundreds unread.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_unread_mark_read`$
CREATE PROCEDURE `contact_unread_mark_read`(
  IN _user_id VARCHAR(16),
  IN _event VARCHAR(100)
)
BEGIN
  DECLARE _mtime INT(11) UNSIGNED;
  DECLARE _marked INT(11) UNSIGNED DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _mtime;

  UPDATE yp.contact_activity c
     SET c.dismissed_at = _mtime
   WHERE c.target_uid = _user_id
     AND c.event = _event
     AND c.dismissed_at IS NULL
     AND contact_unread_counted(c.event, c.uid, c.hidden_at, _user_id) = 1;
  SELECT ROW_COUNT() INTO _marked;

  SELECT 'ok' AS status, _event AS event, _marked AS marked, _mtime AS dismissed_at;
END$

DELIMITER ;
