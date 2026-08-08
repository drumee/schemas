DELIMITER $

-- =========================================================
-- reward_claim_track
--
-- Record how far a user got in the claim-reward flow
-- (ui-team builtins/widget/reward-flow), one row per user,
-- and AWARD the limited reward slot when they finish.
--
-- Both columns advance MONOTONICALLY, by rank:
--   status  emailed(1) < clicked(2) < left(3) < started(4)
--                   < dropped(5) < missed(6) < done(7)
--   step    step1(1) < step2(2) < step3(3)
--
-- so `step` always holds the FURTHEST point reached, which is
-- what makes "dropped at step 2" meaningful, and no late or
-- out-of-order post can undo a completion. A user who left and
-- later came back to finish still ends up `done` (7 > 3).
--
-- LEFT AND DROPPED ARE NOT THE SAME THING, and keeping them
-- apart is the whole reason there are two.
--
--   left     -- the user WENT AWAY without saying anything: a
--              refresh, a closed tab, a browser that vanished.
--              Recoverable, because a stray F5 must not cost
--              someone a prize they were three clicks from
--              claiming.
--   dropped  -- the user SAID NO, out loud, by pressing "Drop
--              anyway" on the confirmation. Terminal.
--
-- The names follow the BUTTON, which is the only vocabulary
-- anyone outside this file shares: it says "Drop anyway", so
-- what it records is a drop. Naming the deliberate refusal
-- 'declined' and the accidental exit 'dropped' inverted that,
-- and the first person to read the funnel -- looking at their
-- own row after pressing that button -- asked why "dropped at
-- step 2" said declined.
--
-- They were briefly the same status, and the moment the
-- accidental exit was made recoverable the deliberate one
-- silently became non-binding with it: the user refused the
-- offer and got it again at their next login, forever. Two
-- statuses is what stops one decision about accidental exits
-- from overriding a deliberate one.
--
-- LEFT SITS BELOW STARTED, which is not where a terminal state
-- would go -- and that is the point: it is not one. The desk
-- gate re-opens the flow for a user who left
-- (reward.get_state OPEN), so coming back and reaching a card
-- step has to be able to clear it. Ranking it above 'started'
-- froze the row: a returning user read as gone on the dashboard
-- while they were on screen working, and "In progress"
-- undercounted them by exactly that population.
--
-- Everything above it still sticks. 'dropped', 'missed' and
-- 'done' all outrank it, so neither a deliberate refusal, the
-- cap refusal, nor a completion can be undone by a later
-- abandon -- which matters most for 'dropped', since the leave
-- beacon and the drop both fire on the way out of the same
-- screen and their order is not guaranteed.
--
-- ONE EXCEPTION TO THE LADDER: a 'left' post is accepted onto
-- a row that is 'started'. Without it 'left' could never be
-- written AT ALL -- the widget posts 'started' the moment it
-- mounts, so every row is already there by the time a user
-- abandons, and a pure rank test would reject the very write
-- that records it.
--
-- 'started' and 'left' are the only REVERSIBLE states in the
-- funnel: they say where the user is right now, and a user can
-- leave and come back as often as they like. Every other status
-- records a fact that happened once -- the mail went out, the
-- link was followed, the cap refused them, they finished -- and
-- none of those is takeable back. So the exception is scoped to
-- exactly that pair, and to nothing else: it cannot fire against
-- 'missed' or 'done' because it tests for 'started' by name.
--
-- `clicked` sits between emailed and started because being
-- MAILED is not the entitlement on its own -- the user has to
-- follow the campaign link. Only 'clicked' and 'started' open
-- the flow (see reward.get_state), so someone who was sent the
-- mail and simply logs in gets nothing.
--
-- `missed` outranks 'started' and 'left' so it STICKS for
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
-- The campaign is capped at sys_conf.reward_conf -> $.slots
-- (100 when unset). Reporting 'done' is therefore a REQUEST for
-- a slot, not a statement of fact: the answer is the `status` on
-- the row this returns -- 'done' when the slot was granted,
-- 'missed' when the cap had already closed. The widget shows
-- Congratulations or the sold-out screen accordingly.
--
-- The limit is read HERE rather than passed in, and the
-- signature deliberately did not change. It was briefly a
-- parameter, which coupled this file to a server deploy: the
-- moment the proc required the extra argument, every caller
-- still running the previous build failed with "Incorrect
-- number of arguments" -- caught on stage, where three runtimes
-- call it. Reading the config is also simply the right home for
-- it: this is where the award decision is made, so nothing
-- upstream has to agree about the number for the cap to hold.
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
--
-- AND THE PRIZE ITSELF
--
-- An awarded slot now also grants it: reward_grant_storage
-- writes the yp.quota entitlement for 5 years of unlimited
-- storage. It is CALLed here, inside the lock, so a user can
-- never consume one of the campaign's places and receive
-- nothing -- which is exactly what happened for as long as the
-- award was a counter and the prize was a screen.
-- =========================================================
DROP PROCEDURE IF EXISTS `reward_claim_track`$
CREATE PROCEDURE `reward_claim_track`(
  IN _uid VARCHAR(16),
  IN _campaign VARCHAR(64),
  IN _status VARCHAR(16),
  IN _step VARCHAR(16)
)
BEGIN
  DECLARE _s VARCHAR(16) DEFAULT NULL;
  -- The status actually written. Differs from _status only when a 'done'
  -- request is refused, which is the one decision this proc makes.
  DECLARE _eff VARCHAR(16) DEFAULT NULL;
  DECLARE _held INT DEFAULT 0;
  DECLARE _claimed INT DEFAULT 0;
  DECLARE _locked INT DEFAULT 0;
  DECLARE _limit INT DEFAULT 100;
  DECLARE _slots VARCHAR(32) DEFAULT NULL;

  SET _s = NULLIF(_step, '');
  SET _eff = _status;

  IF _status = 'done' THEN
    -- A scalar subquery rather than SELECT ... INTO: a missing key yields NULL
    -- here, where INTO would raise a NOT FOUND condition and leave the variable
    -- silently untouched.
    SET _slots = JSON_VALUE(
      (SELECT conf_value FROM sys_conf WHERE conf_key = 'reward_conf'), '$.slots');

    -- Tested as TEXT before converting, never cast blind: CAST('abc' AS SIGNED)
    -- raises "Truncated incorrect INTEGER value" under strict mode, which would
    -- abort the whole completion -- one bad character in a config value would
    -- stop users claiming a reward they had earned. The pattern also rejects 0
    -- and leading zeros, so a configured 0 falls back to the default instead of
    -- closing the campaign to everybody.
    --
    -- Every other way of getting this wrong lands here too: a missing key, a
    -- conf_value that is not JSON, and a $.slots that is absent all leave
    -- _slots NULL, and NULL REGEXP is NULL, which takes the ELSE.
    SET _limit = IF(_slots REGEXP '^[1-9][0-9]*$', CAST(_slots AS SIGNED), 100);

    SELECT COUNT(*) INTO _held
      FROM reward_claim WHERE uid = _uid AND completed_count > 0;

    -- INELIGIBLE USERS MUST NOT CONSUME A PLACE.
    --
    -- The prize is a PERSONAL entitlement, and a user covered by an org
    -- entitlement cannot hold one -- every resolver is tenant-first, so the row
    -- would never be read (see reward_personal_eligible).
    --
    -- Refused HERE, and not only in reward_grant_storage, because the two
    -- decisions have to be the same decision. When the grant refused on its own,
    -- an org member still passed through the award below: completed_count went
    -- to 1, reward_slots_used counted them, and one of the campaign's limited
    -- places was gone for good on a user who received nothing for it.
    --
    -- 'missed' rather than a status of its own: it is the one the widget already
    -- renders (the sold-out screen), it outranks 'started'/'left' so it
    -- sticks, and it sits under 'done' so it can never take a slot back off
    -- someone who legitimately holds one. reward.get_state turns these users
    -- away before Step 1, so arriving here at all means a browser that was open
    -- when they joined an organisation.
    IF _held = 0 AND reward_personal_eligible(_uid) = 0 THEN
      SET _eff = 'missed';
    END IF;

    IF _held = 0 AND _eff = 'done' THEN
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

  INSERT INTO reward_claim (uid, campaign, status, step, clicked_at, completed_count, completed_at, ctime, mtime)
  VALUES (
    _uid,
    IFNULL(NULLIF(_campaign, ''), 'free-storage'),
    _eff,
    _s,
    IF(_eff = 'clicked', UNIX_TIMESTAMP(), 0),
    IF(_eff = 'done', 1, 0),
    IF(_eff = 'done', UNIX_TIMESTAMP(), 0),
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
    -- Written once, on the FIRST granted completion, and never moved: it is the
    -- start of the 5-year reward term (reward_grant_storage reads it), and a
    -- re-armed user finishing again is a second completion but not a second
    -- prize. Guarded on its own old value rather than on `status`, so it does
    -- not care where it sits relative to the reassignment below.
    completed_at = IF(_eff = 'done' AND completed_at = 0, UNIX_TIMESTAMP(), completed_at),
    -- The rank test, plus the started -> left exception the header
    -- explains. Written as an OR rather than folded into the ranking because
    -- it is not a ranking: it is one named pair of reversible states, and a
    -- rank order that expressed it would have to make 'left' both above
    -- and below 'started'.
    status = IF(
      IFNULL(FIELD(_eff, 'emailed', 'clicked', 'left', 'started', 'dropped', 'missed', 'done'), 0) >
      IFNULL(FIELD(status, 'emailed', 'clicked', 'left', 'started', 'dropped', 'missed', 'done'), 0)
      OR (_eff = 'left' AND status = 'started'),
      _eff, status
    ),
    step = IF(
      IFNULL(FIELD(_s, 'step1', 'step2', 'step3'), 0) >
      IFNULL(FIELD(step, 'step1', 'step2', 'step3'), 0),
      _s, step
    ),
    mtime = UNIX_TIMESTAMP();

  -- MATERIALISE THE PRIZE.
  --
  -- Until this call the campaign awarded a slot and nothing else: the widget
  -- said "5 years of unlimited storage" while every resolver went on handing
  -- the user 5 GB. reward_grant_storage writes the yp.quota entitlement that
  -- makes the congratulations screen true.
  --
  -- Inside the lock, and only on an award (_eff, not _status -- a refused
  -- completion arrives here as 'missed' and must not be paid). Slot and prize
  -- are taken together, so there is no ordering in which a user consumes one of
  -- the campaign's 100 places and gets nothing for it.
  --
  -- After the upsert, because the grant reads completed_at back off the row.
  --
  -- Idempotent by construction, which is what makes it safe on the re-armed
  -- second completion this proc explicitly allows: same completed_at, same
  -- period_end, same row.
  IF _eff = 'done' THEN
    CALL reward_grant_storage(_uid);
  END IF;

  IF _locked = 1 THEN
    DO RELEASE_LOCK('reward_slot');
  END IF;

  SELECT * FROM reward_claim WHERE uid = _uid;
END $

DELIMITER ;
