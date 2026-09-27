DELIMITER $

-- Take a workspace invitation out of the recipient's notification feed, once
-- they have answered it.
--
-- WHY THE SERVER HAS TO DO THIS AND THE CLIENT CANNOT. An invitation can be
-- answered from two places: the notification row, which knows its own
-- contact_activity id and could dismiss itself through the ordinary
-- contact_activity_dismiss; and the EMAIL, which knows only the token. Leaving
-- it to the client means the email path never dismisses anything -- the
-- invitation is accepted, the person is already a member, and the bell still
-- offers them Accept and Decline on a token that will answer 'already_used'.
-- Both hub.accept_invite and hub.decline_invite call this, so the row goes
-- whichever way the answer arrived.
--
-- KEYED ON (recipient, workspace), NOT on an id, for the same reason: the
-- answer names a workspace, not a notification. It also cleans up correctly
-- when more than one row exists -- two admins inviting the same person to the
-- same workspace write one contact_activity row each (contact_log_activity
-- dedupes per inviter, not per workspace), and answering the invitation
-- answers all of them. notification_hub_invites already collapses those to the
-- newest for display, so leaving the others undismissed would resurrect an
-- older duplicate the moment the newest one went.
--
-- dismissed_at, NOT deleted_at. Dismissal is "read / acknowledged" -- it is
-- what notification_hub_invites and the bell badge filter on -- while
-- deleted_at is the trash button, an explicit removal by the user. Answering an
-- invitation is the former: the row has served its purpose and stops being
-- offered, but it stays in the activity history where the user can still see
-- that they were invited. Stamping deleted_at here would erase that.
--
-- ONLY ROWS NOT ALREADY DISMISSED are touched, so an invitation answered twice
-- (a stale email link pressed after accepting from the bell) keeps the moment
-- it was first acknowledged rather than having it pushed forward.
--
-- Lives in yellow_page because yp.contact_activity does. The drumate-side
-- contact_activity_dismiss takes an activity id and is left alone -- it is the
-- user pressing "mark read" on one row, a different act with a different key.
DROP PROCEDURE IF EXISTS `contact_activity_dismiss_hub_invite`$
CREATE PROCEDURE `contact_activity_dismiss_hub_invite`(
  IN _target_uid VARCHAR(16),
  IN _hub_id     VARCHAR(16)
)
BEGIN
  UPDATE contact_activity
     SET dismissed_at = UNIX_TIMESTAMP()
   WHERE target_uid = _target_uid
     AND event = 'hub_invite_received'
     AND dismissed_at IS NULL
     AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.hub_id')) = _hub_id;
END$

DELIMITER ;
