DELIMITER $
-- =========================================================
-- invite_track_mark
--
-- Record that a workspace invitation was SENT. One contract
-- shared by every call site that can send one, so the five of
-- them cannot drift into recording four different things --
-- the same reason feature_mark exists for yp.feature_usage.
--
-- Callers (server-team):
--   hub.invite            both branches -- the newcomer one and
--                         the isDrumate one that recorded nothing
--                         at all before this
--   hub.invite_with_roles once per assignment
--   secure_share          the pending-invitation path
--
-- FIRST INVITE WINS. The ON DUPLICATE KEY clause deliberately
-- omits sent_time and inviter_id, so a re-send to the same
-- address on the same workspace is a no-op on both. Without
-- that, `invites_sent` would climb every time somebody re-sent
-- and the accept rate would fall -- reporting a decline in
-- persuasion where the only thing that happened was a nudge.
--
-- WHAT A RE-SEND MAY STILL DO is fill in what was missing: an
-- invitee_uid, or an accept_time, or a real inviter over a
-- backfilled NULL. Those use IFNULL/GREATEST so the row can
-- only ever gain information, never lose it. approx is cleared
-- when a measured row lands on top of a backfilled one -- the
-- moment is now known, so the stand-in mark must go.
--
-- _had_account = 1 STAMPS accept_time = sent_time. An existing
-- drumate is granted membership by the caller on the spot, so
-- the invitation is accepted by construction and there is no
-- later redemption event to wait for. Leaving accept_time NULL
-- there would count a granted member as a pending invitation
-- forever.
--
-- EMAIL IS LOWERCASED HERE, not by the callers. The unique key
-- is (hub_id, invitee_email) and the invite panel does not
-- normalise before sending -- "Foo@Bar.com" and "foo@bar.com"
-- would otherwise be two invitations to one person, inflating
-- sent and halving the accept rate for that pair.
-- =========================================================
DROP PROCEDURE IF EXISTS `invite_track_mark`$
CREATE PROCEDURE `invite_track_mark`(
  IN _inviter_id  VARCHAR(16),
  IN _hub_id      VARCHAR(16),
  IN _email       VARCHAR(512),
  IN _invitee_uid VARCHAR(16),
  IN _had_account TINYINT(1),
  IN _source      VARCHAR(32)
)
proc_body: BEGIN
  DECLARE _now INT(11) UNSIGNED;

  -- Nothing to key on: refuse rather than write a row that can never be
  -- matched by invite_track_accept, and that would count as a sent
  -- invitation nobody can ever accept.
  IF _hub_id IS NULL OR _email IS NULL OR TRIM(_email) = '' THEN
    LEAVE proc_body;
  END IF;

  SET _now = UNIX_TIMESTAMP();

  INSERT INTO invite_track
    (inviter_id, hub_id, invitee_email, invitee_uid,
     sent_time, accept_time, had_account, source, approx)
  VALUES
    (_inviter_id, _hub_id, LOWER(TRIM(_email)), _invitee_uid,
     _now, IF(_had_account = 1, _now, NULL), IFNULL(_had_account, 0),
     IFNULL(_source, 'hub_invite'), 0)
  ON DUPLICATE KEY UPDATE
    -- Gain information only. sent_time and had_account are absent on purpose:
    -- both describe the FIRST invitation and must not be rewritten by a later
    -- one. See the header.
    inviter_id  = IFNULL(inviter_id, _inviter_id),
    invitee_uid = IFNULL(invitee_uid, _invitee_uid),
    accept_time = IF(_had_account = 1, IFNULL(accept_time, _now), accept_time),
    -- A measured write lands on top of a backfilled stand-in: the row is no
    -- longer an approximation, so it must stop being marked as one.
    approx      = 0;
END proc_body $

DELIMITER ;
