DELIMITER $

-- Turn down a workspace invitation, by the secret from its email link or its
-- notification row. The counterpart of token_hub_invite_set_status(_, 'accepted', _).
--
-- ONLY AN ACTIVE TOKEN IS DECLINED. An already-accepted one is left exactly as
-- it is: the person is a member, and a stale link pressed afterwards must not
-- rewrite the record of how they got in. It does not remove their membership
-- either -- leaving a workspace is leave_hub, a different act with a different
-- permission. An already-declined one is left alone too, so pressing Decline
-- twice keeps the first answer (same first-refusal-wins rule as
-- invite_track_decline).
--
-- 🚨 expiry IS ZEROED, AND THAT IS THE POINT, not tidying.
-- token_hub_invite_add opens by deleting every hub_invite token whose expiry
-- has passed. Invitations are minted with a 7-day expiry, so a declined row
-- left with its expiry would be swept away a week later and the workspace's
-- Access panel would quietly lose the "Declined" line -- the admin would see
-- the person disappear from Pending Invitations with no record of an answer,
-- which reads exactly like the invitation was never sent. Zero means "no
-- expiry" everywhere in this table, so the refusal survives until the admin
-- acts on it.
--
-- A DECLINED TOKEN CANNOT BE REDEEMED, and zeroing the expiry does not change
-- that: hub.accept_invite tests `expiry > 0 && now > expiry` for staleness and
-- `status !== 'active'` separately, and the status test is what refuses this
-- one. The never-expiring row is a record, not a live invitation.
--
-- RE-INVITING AFTER A REFUSAL WORKS, and must: token_hub_invite_add is a
-- REPLACE on (email, method, inviter_id), so the same admin inviting the same
-- address to the same workspace again overwrites this row with a fresh active
-- token. A different admin creates a second row instead, and the declined one
-- stays beside it -- hub_invitations collapses those to the newest per address
-- so the panel shows one line, and it shows Pending.
--
-- The row is returned so the caller can act on the invitation it just closed
-- without parsing `method` itself -- it still has to delete the matching
-- pending_invitation row and record the refusal in invite_track. Returned even
-- when nothing was updated, so the caller can tell "already answered" from
-- "no such invitation" (which returns no row at all).
DROP PROCEDURE IF EXISTS `token_hub_invite_decline`$
CREATE PROCEDURE `token_hub_invite_decline`(
  IN _secret VARCHAR(255)
)
BEGIN
  UPDATE token
     SET `status` = 'declined',
         expiry   = 0
   WHERE `secret` = _secret
     AND method LIKE 'hub_invite:%'
     AND `status` = 'active';

  SELECT email, `secret`, method, inviter_id, `status`, ctime, expiry, metadata,
         SUBSTRING(method FROM 12) AS hub_id
    FROM token
   WHERE `secret` = _secret
     AND method LIKE 'hub_invite:%';
END$

DELIMITER ;
