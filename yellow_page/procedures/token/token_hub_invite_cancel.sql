DELIMITER $

-- An administrator withdraws an invitation to a workspace: the Cancel button
-- on a row of the Access panel's Pending Invitations section (hub.cancel_invite).
--
-- EVERY INVITER'S ROW GOES, not only the caller's. The token unique key carries
-- inviter_id, so two admins inviting the same address leave two rows, and the
-- panel shows that person once (hub_invitations, newest row wins). Cancelling
-- the one row the panel happened to show would bring the older invitation back
-- on the next read -- the person would still be invited.
--
-- ONLY 'active' AND 'declined'. An accepted token is how a member got in and
-- stays as that record; withdrawing it would change nothing about the
-- membership and would erase its history.
--
-- THE PENDING ROW IS DELETED HERE TOO, and only when a token was. That row is
-- what signup grants from (_resolve_pending_invitation) and what the seat count
-- reads, so leaving it would let a cancelled invitee join on signup and keep
-- their seat taken. Tied to a token actually being withdrawn so an address that
-- reached pending_invitation by some other path, with no invitation of this
-- kind, is left alone.
--
-- Returns how many invitation tokens were withdrawn; 0 means there was nothing
-- left to cancel (already answered, superseded or swept).
DROP PROCEDURE IF EXISTS `token_hub_invite_cancel`$
CREATE PROCEDURE `token_hub_invite_cancel`(
  IN _hub_id VARCHAR(16),
  IN _email  VARCHAR(512)
)
BEGIN
  DECLARE _cancelled INT DEFAULT 0;

  IF _hub_id IS NOT NULL AND _hub_id <> '' AND _email IS NOT NULL AND _email <> '' THEN
    DELETE FROM token
     WHERE method = CONCAT('hub_invite:', _hub_id)
       AND email = _email
       AND `status` IN ('active', 'declined');
    SET _cancelled = ROW_COUNT();

    IF _cancelled > 0 THEN
      DELETE FROM pending_invitation
       WHERE hub_id = _hub_id
         AND email = _email;
    END IF;
  END IF;

  SELECT _cancelled AS cancelled;
END$

DELIMITER ;
