DELIMITER $

-- Retire workspace invitations that have lapsed: the token AND the
-- pending_invitation row it was minted with.
--
-- WHY THE PENDING ROW HAS TO GO TOO. hub.invite writes both: the token is what
-- Accept/Decline answer, the pending row is what signup grants from
-- (pending_invitation_get_by_email) and what the seat count reads
-- (member_list_stats). The expiry sweep used to delete only the token, so a
-- lapsed invitation lived on as a pending row with expiry_time 0 -- it kept
-- its seat for ever, and the address could still sign up and land in the
-- workspace days after the invitation had "expired". The pending row cannot
-- carry the expiry itself: signup passes its expiry_time on to add_member and
-- permission_grant as the MEMBERSHIP's expiry.
--
-- A PENDING ROW IS KEPT while any other live invitation of the same address to
-- the same workspace exists (another admin's, or a re-send) -- it belongs to
-- that one now.
--
-- The token delete is the sweep token_hub_invite_add has always run (expired
-- hub_invite tokens of any status), unchanged; the pending rows go first,
-- while the tokens that identify them are still there.
--
-- NEVER RAISES. It is called from the top of procedures on hot paths
-- (token_hub_invite_add, member_list_stats, pending_invitation_get_by_email),
-- and an SQL error there ends the caller's shared connection in the server's
-- mariadb wrapper. A sweep that fails (a deadlock with a concurrent sweep)
-- simply leaves the rows for the next one.
DROP PROCEDURE IF EXISTS `hub_invite_expire_sweep`$
CREATE PROCEDURE `hub_invite_expire_sweep`()
BEGIN
  DECLARE _now INT(11) UNSIGNED;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

  SET _now = UNIX_TIMESTAMP();

  IF EXISTS (
    SELECT 1 FROM token
     WHERE method LIKE 'hub_invite:%' AND expiry > 0 AND _now > expiry
  ) THEN
    DELETE pi FROM pending_invitation pi
      JOIN token t
        ON t.method = CONCAT('hub_invite:', pi.hub_id)
       AND t.email = pi.email
     WHERE t.`status` = 'active'
       AND t.expiry > 0
       AND _now > t.expiry
       AND NOT EXISTS (
         SELECT 1 FROM token l
          WHERE l.method = t.method
            AND l.email = t.email
            AND l.`status` = 'active'
            AND (l.expiry = 0 OR l.expiry >= _now)
       );

    DELETE FROM token
     WHERE method LIKE 'hub_invite:%' AND expiry > 0 AND _now > expiry;
  END IF;
END$

DELIMITER ;
