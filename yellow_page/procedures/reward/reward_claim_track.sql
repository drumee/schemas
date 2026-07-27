DELIMITER $

-- =========================================================
-- reward_claim_track
--
-- Record how far a user got in the claim-reward flow
-- (ui-team builtins/widget/reward-flow), one row per user.
--
-- Both columns advance MONOTONICALLY, by rank:
--   status  emailed(1) < started(2) < dropped(3) < done(4)
--   step    step1(1) < step2(2) < step3(3)
--
-- so `step` always holds the FURTHEST point reached, which is
-- what makes "dropped at step 2" meaningful, and no late or
-- out-of-order post can undo a completion. A user who dropped
-- and later came back to finish still ends up `done` (4 > 3).
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

  INSERT INTO reward_claim (uid, campaign, status, step, ctime, mtime)
  VALUES (
    _uid,
    IFNULL(NULLIF(_campaign, ''), 'free-storage'),
    _status,
    _s,
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  )
  ON DUPLICATE KEY UPDATE
    status = IF(
      IFNULL(FIELD(_status, 'emailed', 'started', 'dropped', 'done'), 0) >
      IFNULL(FIELD(status, 'emailed', 'started', 'dropped', 'done'), 0),
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
