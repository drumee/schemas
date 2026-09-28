DELIMITER $

-- Record that ONE workspace invitation was accepted.
--
-- invite_track_accept already exists and takes the address alone, stamping
-- every row still open for it. That is right where it is called: account
-- creation resolves every pending invitation the address holds in a single
-- pass, so they really are all accepted at the same moment.
--
-- 🚨 IT IS WRONG FOR AN ANSWER TO ONE INVITATION, and that is now the main
-- path. hub.accept_invite redeems a single token for a single workspace.
-- Calling the per-address procedure there would mark somebody's other pending
-- invitations -- to workspaces they have not answered, and may yet decline --
-- as accepted, on the strength of them saying yes to a different one. The
-- refusal side already has this shape (invite_track_decline); this is its
-- counterpart, and the pair keeps a per-invitation answer per-invitation.
--
-- FIRST ACCEPTANCE WINS, via `accept_time IS NULL`, exactly as in
-- invite_track_accept: an address re-invited after joining, then redeeming
-- again, must not have its original acceptance moment pushed forward, or
-- time-to-accept would silently shorten.
--
-- decline_time IS NOT CLEARED. Refused in March, invited again in June,
-- joined: both are true and the row records both. Nothing in invite_track is
-- ever cleared.
--
-- invitee_uid IS FILLED IN over a NULL and never overwritten -- for an address
-- that had no account when it was invited, redemption is the first moment
-- there is an account to name.
--
-- THE ROW MAY NOT EXIST, and that is not an error. invite_track is analytics
-- and every writer of it is wrapped so a failed counter cannot fail the
-- operation it counts; an invitation sent before this table existed is still
-- acceptable and simply matches nothing. Never INSERT here -- sent_time would
-- be a guess and a fabricated row would inflate invites_sent.
--
-- EMAIL IS LOWERCASED to match invite_track_mark/_v2, whose unique key is
-- (hub_id, invitee_email). An acceptance that failed to match its own sent row
-- would be invisible twice over: the invitation would look pending forever AND
-- the acceptance would never be counted.
DROP PROCEDURE IF EXISTS `invite_track_accept_hub`$
CREATE PROCEDURE `invite_track_accept_hub`(
  IN _hub_id VARCHAR(16),
  IN _email  VARCHAR(512),
  IN _uid    VARCHAR(16)
)
BEGIN
  UPDATE invite_track
     SET accept_time = UNIX_TIMESTAMP(),
         invitee_uid = IFNULL(invitee_uid, _uid)
   WHERE hub_id = _hub_id
     AND invitee_email = LOWER(TRIM(_email))
     AND accept_time IS NULL;
END$

DELIMITER ;
