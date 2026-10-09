-- One-time clean-up: pending_invitation rows left behind by workspace
-- invitations that lapsed before hub_invite_expire_sweep existed.
--
-- The old expiry sweep (token_hub_invite_add) deleted only the TOKEN, so each
-- lapsed hub.invite left its pending row behind with expiry_time 0: still
-- holding a seat in member_list_stats, still granting membership on signup,
-- and invisible in the Access panel, so nobody could cancel it.
--
-- ONLY ROWS PROVABLY MINTED BY hub.invite are removed -- those with an
-- invite_track row of source 'hub_invite' for the same workspace and address.
-- pending_invitation is also written by other paths (secure-share approval,
-- add_contributors) that mint no hub_invite token; a row with no token is
-- normal for them, so it is left alone when its origin cannot be shown.
--
-- And only when no live invitation remains for that person and workspace, and
-- the row is older than the 7-day invitation lifetime. hub.invite mints the
-- token before the pending row and cancel/decline/accept delete the pending
-- row with it, so a hub_invite row with no live token is a lapsed invitation.
DELETE pi FROM pending_invitation pi
 WHERE pi.created_at < UNIX_TIMESTAMP() - 7 * 86400
   AND EXISTS (
     SELECT 1 FROM invite_track it
      WHERE it.hub_id = pi.hub_id
        AND it.invitee_email = pi.email
        AND it.source = 'hub_invite'
   )
   AND NOT EXISTS (
     SELECT 1 FROM token t
      WHERE t.method = CONCAT('hub_invite:', pi.hub_id)
        AND t.email = pi.email
        AND t.`status` = 'active'
        AND (t.expiry = 0 OR t.expiry >= UNIX_TIMESTAMP())
   );
