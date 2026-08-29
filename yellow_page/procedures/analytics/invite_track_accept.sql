DELIMITER $
-- =========================================================
-- invite_track_accept
--
-- Record that a workspace invitation was REDEEMED. Called at
-- account creation, when the pending invitations queued against
-- an address are resolved into real memberships.
--
-- Callers (server-team): signup._resolve_pending_invitation and
-- butler._resolve_pending_invitation. Those two are mirrors of
-- each other and both must call this -- an account created
-- through one path and not the other would be an acceptance
-- that never got counted, silently lowering the accept rate for
-- whichever path was missed.
--
-- ALL PENDING ROWS FOR THE ADDRESS, not one. A person invited to
-- three workspaces before signing up accepts all three with one
-- sign-up: _resolve_pending_invitation grants every pending
-- membership in a single pass, so every matching row is redeemed
-- at the same moment. Taking a hub_id and running this three
-- times would be the same writes with three chances for one to
-- be skipped.
--
-- FIRST ACCEPTANCE WINS -- the WHERE clause requires
-- accept_time IS NULL. An address that is invited again after
-- redemption, then re-resolved, must not have its original
-- acceptance moment overwritten with a later one; the funnel's
-- time-to-accept would silently shorten.
--
-- invitee_uid IS SET HERE and nowhere else for the newcomer
-- branch, because this is the first moment the account exists.
-- Until then the row identifies the person only by the address
-- they were invited at.
--
-- EMAIL IS LOWERCASED to match invite_track_mark. Sign-up
-- normalises inconsistently across paths, and an acceptance
-- that fails to match its own sent row is invisible twice over:
-- the invitation stays pending forever AND the acceptance is
-- never counted.
-- =========================================================
DROP PROCEDURE IF EXISTS `invite_track_accept`$
CREATE PROCEDURE `invite_track_accept`(
  IN _email VARCHAR(512),
  IN _uid   VARCHAR(16)
)
BEGIN
  UPDATE invite_track
     SET accept_time = UNIX_TIMESTAMP(),
         invitee_uid = IFNULL(invitee_uid, _uid)
   WHERE invitee_email = LOWER(TRIM(_email))
     AND accept_time IS NULL;
END $

DELIMITER ;
