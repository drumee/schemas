DELIMITER $

-- WHY A _v2 AND NOT AN EDIT TO invite_track_mark.
--
-- Same arity, same parameters, one different rule: had_account = 1 no longer
-- stamps accept_time. So this could not have been ER_SP_WRONG_NO_OF_ARGS, and
-- that is exactly what makes editing in place the dangerous option -- the old
-- server would have kept calling it, kept granting membership on the spot, and
-- kept reporting every one of those grants as an invitation nobody had answered
-- yet. A silent, permanent under-count of acceptances on production, with a
-- green log either way and no moment at which anything failed.
--
-- The two procedures are both correct, for different callers:
--
--   invite_track_mark     the caller GRANTS membership itself, so the
--                         invitation is accepted at the instant it is sent.
--   invite_track_mark_v2  the caller SENDS an invitation the recipient must
--                         answer, so nothing is accepted yet.
--
-- Leave the old one in place. Nothing about it is wrong for the server that
-- still calls it, and deleting it is how the outage in feedback_schema_env
-- happened.
--
-- EVERYTHING ELSE IS UNCHANGED from invite_track_mark, deliberately, so the
-- diff between the two is one line of behaviour and not a rewrite:
--
--   FIRST INVITE WINS -- the ON DUPLICATE KEY clause omits sent_time and
--   had_account, so a re-send to the same address on the same workspace is a
--   no-op on both. Without it `invites_sent` would climb on every nudge and the
--   accept rate would fall, reporting a decline in persuasion where the only
--   thing that happened was a reminder.
--
--   GAIN INFORMATION ONLY -- invitee_uid and inviter_id fill in over a NULL and
--   are never overwritten; approx is cleared when a measured row lands on top
--   of a backfilled stand-in, because the moment is now known.
--
--   EMAIL IS LOWERCASED HERE, not by the callers, because the unique key is
--   (hub_id, invitee_email) and the invite panel does not normalise before
--   sending -- "Foo@Bar.com" and "foo@bar.com" would otherwise be two
--   invitations to one person.
--
-- decline_time IS NOT TOUCHED, including on a re-invitation. A row that records
-- a refusal keeps recording it: "they said no in March, were asked again in
-- June" is two facts, and the June invitation does not unmake the March answer.
-- Whether they are in the workspace today is accept_time's question, not this
-- one. Consistent with the gain-information-only rule above -- nothing in this
-- table is ever cleared.
DROP PROCEDURE IF EXISTS `invite_track_mark_v2`$
CREATE PROCEDURE `invite_track_mark_v2`(
  IN _inviter_id  VARCHAR(16),
  IN _hub_id      VARCHAR(16),
  IN _email       VARCHAR(512),
  IN _invitee_uid VARCHAR(16),
  IN _had_account TINYINT(1),
  IN _source      VARCHAR(32)
)
BEGIN
  DECLARE _now INT(11) UNSIGNED;

  -- Nothing to key on: write nothing rather than a row that invite_track_accept
  -- can never match, and that would count as a sent invitation nobody can ever
  -- accept.
  IF _hub_id IS NOT NULL AND _email IS NOT NULL AND TRIM(_email) <> '' THEN
    SET _now = UNIX_TIMESTAMP();

    INSERT INTO invite_track
      (inviter_id, hub_id, invitee_email, invitee_uid,
       sent_time, accept_time, had_account, source, approx)
    VALUES
      (_inviter_id, _hub_id, LOWER(TRIM(_email)), _invitee_uid,
       _now, NULL, IFNULL(_had_account, 0),
       IFNULL(_source, 'hub_invite'), 0)
    ON DUPLICATE KEY UPDATE
      inviter_id  = IFNULL(inviter_id, _inviter_id),
      invitee_uid = IFNULL(invitee_uid, _invitee_uid),
      approx      = 0;
  END IF;
END$

DELIMITER ;
