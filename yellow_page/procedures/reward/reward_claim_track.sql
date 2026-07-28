DELIMITER $

-- =========================================================
-- reward_claim_track
--
-- Record how far a user got in the claim-reward flow
-- (ui-team builtins/widget/reward-flow), one row per user.
--
-- Both columns advance MONOTONICALLY, by rank:
--   status  emailed(1) < clicked(2) < started(3)
--                   < dropped(4) < done(5)
--   step    step1(1) < step2(2) < step3(3)
--
-- so `step` always holds the FURTHEST point reached, which is
-- what makes "dropped at step 2" meaningful, and no late or
-- out-of-order post can undo a completion. A user who dropped
-- and later came back to finish still ends up `done` (5 > 4).
--
-- `clicked` sits between emailed and started because being
-- MAILED is not the entitlement on its own -- the user has to
-- follow the campaign link. Only 'clicked' and 'started' open
-- the flow (see reward.get_state), so someone who was sent the
-- mail and simply logs in gets nothing.
--
-- FIELD() returns NULL for a NULL needle and for an unknown
-- value, so both sides are coalesced to 0: without that, the
-- first `step` written onto a row created by reward_claim_emailed
-- (step IS NULL) would compare NULL and never stick.
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

  SET _s = NULLIF(_step, '');

  INSERT INTO reward_claim (uid, campaign, status, step, completed_count, ctime, mtime)
  VALUES (
    _uid,
    IFNULL(NULLIF(_campaign, ''), 'free-storage'),
    _status,
    _s,
    IF(_status = 'done', 1, 0),
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  )
  ON DUPLICATE KEY UPDATE
    -- Counted BEFORE `status` is reassigned below, so it still sees the old
    -- one: a user finishing a re-armed attempt is a second completion, but
    -- re-reporting 'done' on a row already at 'done' is not.
    completed_count = completed_count + IF(_status = 'done' AND status <> 'done', 1, 0),
    status = IF(
      IFNULL(FIELD(_status, 'emailed', 'clicked', 'started', 'dropped', 'done'), 0) >
      IFNULL(FIELD(status, 'emailed', 'clicked', 'started', 'dropped', 'done'), 0),
      _status, status
    ),
    step = IF(
      IFNULL(FIELD(_s, 'step1', 'step2', 'step3'), 0) >
      IFNULL(FIELD(step, 'step1', 'step2', 'step3'), 0),
      _s, step
    ),
    mtime = UNIX_TIMESTAMP();

  SELECT * FROM reward_claim WHERE uid = _uid;
END $

DELIMITER ;
