-- File: schemas/yellow_page/functions/contact_unread_counted.sql
-- Purpose: Whether an UNDISMISSED yp.contact_activity row addressed to
-- _user_id is one the notification panel counts as unread. The single
-- definition behind contact_unread_count / contact_unread_rows /
-- contact_unread_ids / contact_unread_mark_read, so the tab badge, the rows
-- the panel lists and Mark as all read can never disagree. It mirrors the
-- WHERE clauses of the contact_*_unread procedures exactly:
--   - reward_expiry_warning has no self guard (raised by the system sentinel);
--   - every other event needs a sender other than the recipient;
--   - invite_accepted also needs hidden_at IS NULL.
-- dismissed_at is NOT tested here: callers keep it in their own WHERE so the
-- index on target_uid still narrows the scan first.

DELIMITER $

DROP FUNCTION IF EXISTS `contact_unread_counted`$
CREATE FUNCTION `contact_unread_counted`(
  _event VARCHAR(100),
  _uid VARCHAR(16),
  _hidden_at INT(11) UNSIGNED,
  _user_id VARCHAR(16)
)
RETURNS TINYINT(1) DETERMINISTIC
BEGIN
  IF _event = 'reward_expiry_warning' THEN
    RETURN 1;
  END IF;
  IF _uid IS NULL OR _uid = _user_id THEN
    RETURN 0;
  END IF;
  IF _event IN ('task_assigned', 'task_mention', 'task_column_change', 'storage_alert', 'meeting_notice',
                'file_edited', 'file_commented') THEN
    RETURN 1;
  END IF;
  IF _event = 'invite_accepted' AND _hidden_at IS NULL THEN
    RETURN 1;
  END IF;
  RETURN 0;
END$

DELIMITER ;
