DELIMITER $

-- Record that a workspace invitation was REFUSED.
--
-- The mirror of invite_track_accept, and deliberately NOT shaped like it.
-- Acceptance is resolved per ADDRESS: signing up redeems every pending
-- invitation that address holds in one pass, so invite_track_accept takes an
-- email and stamps them all. A refusal is the opposite -- it is an answer to
-- ONE invitation to ONE workspace. Turning down a folder you were invited to in
-- March says nothing about the other two, so this takes a hub_id as well and
-- touches exactly that row.
--
-- FIRST REFUSAL WINS, via `decline_time IS NULL` in the WHERE clause, matching
-- invite_track_accept's first-acceptance-wins rule. Invited again after saying
-- no, and saying no again, keeps the moment they first refused; otherwise
-- time-to-answer would silently stretch every time somebody re-sent.
--
-- accept_time IS NOT CLEARED and is not consulted. A row can hold both: refused
-- in March, invited again in June, joined. Both are true and the table records
-- both. Readers asking "are they in" read accept_time; readers asking "was this
-- ever refused" read decline_time. Nothing in invite_track is ever cleared.
--
-- 🚨 THE ROW MAY LEGITIMATELY NOT EXIST, and that is not an error to raise.
-- invite_track is analytics: every writer of it is wrapped so a failed counter
-- can never fail the operation it is counting. An invitation sent before this
-- table existed, or one whose mark was swallowed, must still be refusable --
-- the UPDATE simply matches nothing. Do NOT be tempted to INSERT a row here:
-- sent_time would be a guess, and a fabricated invitation would inflate
-- invites_sent.
--
-- EMAIL IS LOWERCASED to match invite_track_mark/_v2. The unique key is
-- (hub_id, invitee_email) and the address arrives from whatever the invite
-- panel was given, so a refusal that failed to match its own sent row would be
-- invisible twice over: the invitation would look pending forever AND the
-- refusal would never be counted.
DROP PROCEDURE IF EXISTS `invite_track_decline`$
CREATE PROCEDURE `invite_track_decline`(
  IN _hub_id VARCHAR(16),
  IN _email  VARCHAR(512)
)
BEGIN
  UPDATE invite_track
     SET decline_time = UNIX_TIMESTAMP()
   WHERE hub_id = _hub_id
     AND invitee_email = LOWER(TRIM(_email))
     AND decline_time IS NULL;
END$

DELIMITER ;
