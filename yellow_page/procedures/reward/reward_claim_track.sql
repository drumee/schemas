DELIMITER $

-- =========================================================
-- reward_claim_track
--
-- Record how far a user got in the claim-reward flow
-- (ui-team builtins/widget/reward-flow), one row per user,
-- and AWARD the limited reward slot when they finish.
--
-- Both columns advance MONOTONICALLY, by rank:
--   status  emailed(1) < clicked(2) < started(3)
--                   < dropped(4) < missed(5) < done(6)
--   step    step1(1) < step2(2) < step3(3)
--
-- so `step` always holds the FURTHEST point reached, which is
-- what makes "dropped at step 2" meaningful, and no late or
-- out-of-order post can undo a completion. A user who dropped
-- and later came back to finish still ends up `done` (6 > 4).
--
-- `clicked` sits between emailed and started because being
-- MAILED is not the entitlement on its own -- the user has to
-- follow the campaign link. Only 'clicked' and 'started' open
-- the flow (see reward.get_state), so someone who was sent the
-- mail and simply logs in gets nothing.
--
-- `missed` outranks 'started' and 'dropped' so it STICKS for
-- someone told the reward is gone, but sits under 'done' so no
-- late post can take a slot back off a user who holds one.
--
-- FIELD() returns NULL for a NULL needle and for an unknown
-- value, so both sides are coalesced to 0: without that, the
-- first `step` written onto a row created by reward_claim_emailed
-- (step IS NULL) would compare NULL and never stick.
--
-- THE SLOT AWARD
--
-- The campaign is capped at _limit users (100 by default; the
-- caller reads the `reward_conf` sysconf). Reporting 'done' is
-- therefore a REQUEST for a slot, not a statement of fact: the
-- answer is the `status` on the row this returns -- 'done' when
-- the slot was granted, 'missed' when the cap had already
-- closed. The widget shows Congratulations or the sold-out
-- screen accordingly.
--
-- Counting and awarding must not interleave, or two users
-- finishing together both read 99 and both take slot 100. Each
-- statement here is its own transaction (autocommit), so the
-- count is serialised with GET_LOCK rather than by holding a
-- read lock over a table scan the way SELECT ... FOR UPDATE
-- would. The lock is held for one COUNT and one upsert, on a
-- path that fires at most once per user.
--
-- Failing to TAKE the lock refuses the award. Under contention
-- the only two answers are "wait" and "no", and granting on
-- timeout is exactly the over-award the lock exists to stop.
--
-- A user who ALREADY holds a slot (completed_count > 0) skips
-- the whole check: they finished a re-armed attempt, which is
-- a second completion but not a second slot.
-- =========================================================
DROP PROCEDURE IF EXISTS `reward_claim_track`$
CREATE PROCEDURE `reward_claim_track`(
  IN _uid VARCHAR(16),
  IN _campaign VARCHAR(64),
  IN _status VARCHAR(16),
  IN _step VARCHAR(16),
  IN _limit INT
)
BEGIN
  DECLARE _s VARCHAR(16) DEFAULT NULL;
  -- The status actually written. Differs from _status only when a 'done'
  -- request is refused, which is the one decision this proc makes.
  DECLARE _eff VARCHAR(16) DEFAULT NULL;
  DECLARE _held INT DEFAULT 0;
  DECLARE _claimed INT DEFAULT 0;
  DECLARE _locked INT DEFAULT 0;

  SET _s = NULLIF(_step, '');
  -- 0 and NULL both mean "caller had no configured limit".
  SET _limit = IFNULL(NULLIF(_limit, 0), 100);
  SET _eff = _status;

  IF _status = 'done' THEN
    SELECT COUNT(*) INTO _held
      FROM reward_claim WHERE uid = _uid AND completed_count > 0;
    IF _held = 0 THEN
      SET _locked = IFNULL(GET_LOCK('reward_slot', 5), 0);
      IF _locked = 1 THEN
        SELECT COUNT(*) INTO _claimed FROM reward_claim WHERE completed_count > 0;
        IF _claimed >= _limit THEN
          SET _eff = 'missed';
        END IF;
      ELSE
        SET _eff = 'missed';
      END IF;
    END IF;
  END IF;

  INSERT INTO reward_claim (uid, campaign, status, step, clicked_at, completed_count, ctime, mtime)
  VALUES (
    _uid,
    IFNULL(NULLIF(_campaign, ''), 'free-storage'),
    _eff,
    _s,
    IF(_eff = 'clicked', UNIX_TIMESTAMP(), 0),
    IF(_eff = 'done', 1, 0),
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  )
  ON DUPLICATE KEY UPDATE
    -- First click of the CURRENT attempt only: a re-arm zeroes this, and a
    -- duplicate 'clicked' post must not move the timestamp.
    clicked_at = IF(_eff = 'clicked' AND clicked_at = 0, UNIX_TIMESTAMP(), clicked_at),
    -- Counted BEFORE `status` is reassigned below, so it still sees the old
    -- one: a user finishing a re-armed attempt is a second completion, but
    -- re-reporting 'done' on a row already at 'done' is not. This is also what
    -- makes the row hold a slot, so it is only ever bumped on a GRANTED
    -- completion — a refused one arrives here as 'missed'.
    completed_count = completed_count + IF(_eff = 'done' AND status <> 'done', 1, 0),
    status = IF(
      IFNULL(FIELD(_eff, 'emailed', 'clicked', 'started', 'dropped', 'missed', 'done'), 0) >
      IFNULL(FIELD(status, 'emailed', 'clicked', 'started', 'dropped', 'missed', 'done'), 0),
      _eff, status
    ),
    step = IF(
      IFNULL(FIELD(_s, 'step1', 'step2', 'step3'), 0) >
      IFNULL(FIELD(step, 'step1', 'step2', 'step3'), 0),
      _s, step
    ),
    mtime = UNIX_TIMESTAMP();

  IF _locked = 1 THEN
    DO RELEASE_LOCK('reward_slot');
  END IF;

  SELECT * FROM reward_claim WHERE uid = _uid;
END $

DELIMITER ;
