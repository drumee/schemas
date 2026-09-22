DELIMITER $

-- Remove ONE pending invitation: this address, this workspace.
--
-- pending_invitation_delete_by_email already exists and takes the address
-- alone, clearing every workspace that address was invited to. That is right
-- where it is called -- account creation resolves all of them in one pass, so
-- none is left pending afterwards. It is wrong for a single answer.
--
-- 🚨 WHAT THIS TABLE ACTUALLY DOES, and why a refusal must reach it.
-- pending_invitation is not a record of an invitation; it is the QUEUE that
-- signup grants membership from. signup.create_account and butler both call
-- _resolve_pending_invitation(email), which reads every row for the address and
-- adds the new account to each hub -- with no further consent, because until
-- now there was none to ask for.
--
-- So a refusal that only marked the token would be undone by the invitee
-- signing up afterwards: they would decline the invitation, create their
-- account, and find themselves a member of the workspace they had just turned
-- down. Declining has to delete the row, and this is the procedure that does
-- it, scoped so the invitee's OTHER pending invitations survive an answer
-- about one of them.
--
-- Accepting deletes it too, for the opposite reason: the membership has been
-- granted already, and a row left behind would have signup grant it a second
-- time -- harmless today because add_member is idempotent, but it would also
-- leave the invitation looking unanswered to everything that reads this table,
-- including the admin console's Pending Invites list.
--
-- The refusal itself is recorded on the token (token_hub_invite_decline) and in
-- invite_track (invite_track_decline); this table holds no status column and is
-- not where an answer is remembered.
--
-- EMAIL IS NOT LOWERCASED, unlike invite_track's procedures, because this table
-- is not keyed case-insensitively by convention but by its collation:
-- pending_invitation is utf8mb4_general_ci, so `Foo@Bar.com` and `foo@bar.com`
-- are the SAME key here and either spelling matches the row. Folding the case
-- as well would be harmless but misleading -- it would suggest the caller has
-- to, and the INSERT in yp_add_pending_invitation does not.
DROP PROCEDURE IF EXISTS `pending_invitation_delete`$
CREATE PROCEDURE `pending_invitation_delete`(
  IN _hub_id VARCHAR(16),
  IN _email  VARCHAR(512)
)
BEGIN
  DELETE FROM pending_invitation
   WHERE hub_id = _hub_id
     AND email = _email;
END$

DELIMITER ;
