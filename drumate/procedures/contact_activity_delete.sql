DELIMITER $

DROP PROCEDURE IF EXISTS `contact_activity_delete`$
CREATE PROCEDURE `contact_activity_delete`(
  IN _user_id VARCHAR(16),
  IN _activity_id INT(11) UNSIGNED
)
BEGIN
  -- The trash button for a contact_activity row (contact invites, task
  -- assignments, task @-mentions, watched-column moves, meeting notices,
  -- storage alerts). contact_activity_dismiss keeps meaning "mark read" and is
  -- deliberately NOT touched -- same arity argument as mfs_delete_activity.
  DECLARE _now INT(11) UNSIGNED;
  SELECT UNIX_TIMESTAMP() INTO _now;

  -- dismissed_at is set in the same statement when it is still NULL, because
  -- deleting implies having dealt with it. Without that, trashing a row the
  -- user never opened would leave it unread forever: it would vanish from the
  -- panel while still counting toward the bell badge, giving a badge whose
  -- number points at nothing the user can find. COALESCE preserves an existing
  -- dismissed_at rather than overwriting when it was read earlier, so the
  -- "when did I read this" timestamp survives the delete.
  --
  -- target_uid = _user_id is the security boundary and mirrors
  -- contact_activity_dismiss exactly: this table is shared across all users in
  -- yp, so without it a caller could delete a notification addressed to
  -- somebody else. Unlike the drumate side, scoping here cannot be structural.
  UPDATE yp.contact_activity
     SET deleted_at   = _now,
         dismissed_at = COALESCE(dismissed_at, _now)
   WHERE id = _activity_id
     AND target_uid = _user_id;

  SELECT 'ok' AS status, _activity_id AS activity_id, _now AS deleted_at;
END$

DELIMITER ;
