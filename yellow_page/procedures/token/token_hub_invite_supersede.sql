DELIMITER $

-- Drop every OTHER invitation to the same address for the same workspace, so a
-- person has exactly one live invitation per workspace at a time.
--
-- WHY THIS IS NEEDED AT ALL. token_hub_invite_add is a REPLACE on
-- (email, method, inviter_id), so re-inviting as the SAME admin already
-- overwrites the previous row. A DIFFERENT admin inviting the same address
-- writes a second row beside it, and the first one survives -- including when
-- the first one is a REFUSAL, which token_hub_invite_decline deliberately
-- parks with expiry = 0 so it never ages out.
--
-- 🚨 THE BUG THAT MAKES THIS MORE THAN TIDYING. hub_invitations reports the
-- newest QUALIFYING row, and an expired invitation does not qualify. So:
-- admin A invites, the person declines (row kept forever); admin B invites
-- again; nobody answers and B's invitation lapses after 7 days -- and the
-- panel falls back to A's undying row and reports "Declined" for an
-- invitation the person never refused. Measured on stage before this existed.
--
-- Superseding is also what the panel already appears to do, and what was asked
-- for: one row per person, and re-inviting somebody who declined turns their
-- row back to Pending rather than stacking a second one.
--
-- DELETED, NOT MARKED. A superseded invitation is not an answer and must not
-- be reported as one; leaving it as 'declined' is exactly the state that
-- misleads. The refusal is not lost -- invite_track.decline_time records that
-- this address once refused this workspace, is never cleared, and is what
-- viral_loop counts. This table holds live invitations; that one holds history.
--
-- KEEPS THE ROW JUST MINTED, by secret, rather than by inviter or by time:
-- the caller has it in hand, two invitations can share a ctime second, and
-- matching on anything else risks deleting the one being sent.
--
-- ACCEPTED TOKENS ARE LEFT ALONE. A redeemed invitation is how somebody became
-- a member; hub.accept_invite reads it back and the audit trail depends on it.
-- Only invitations still waiting or refused are superseded.
DROP PROCEDURE IF EXISTS `token_hub_invite_supersede`$
CREATE PROCEDURE `token_hub_invite_supersede`(
  IN _email  VARCHAR(512),
  IN _method VARCHAR(80),
  IN _keep   VARCHAR(255)
)
BEGIN
  IF _email IS NOT NULL AND _method IS NOT NULL AND _keep IS NOT NULL THEN
    DELETE FROM token
     WHERE method = _method
       AND email = _email
       AND `secret` <> _keep
       AND `status` IN ('active', 'declined');
  END IF;
END$

DELIMITER ;
