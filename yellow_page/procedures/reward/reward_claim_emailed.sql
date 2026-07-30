DELIMITER $

-- =========================================================
-- reward_claim_emailed
--
-- Log that the claim-reward campaign mail was accepted for
-- this user, seeding the top of the funnel. Called once per
-- recipient by analytics-server claim_reward().
--
-- A send to someone whose previous attempt ENDED (done,
-- dropped or missed) RE-ARMS them: the row goes back to
-- 'emailed' with no step, so the desk gate — which now asks the
-- server rather than the browser — offers the flow again.
-- Re-sending the mail is therefore a real reset, with no
-- localStorage surgery.
--
-- 'missed' belongs in that set so raising the slot limit and
-- mailing again genuinely re-opens the flow for the people who
-- were turned away. It does NOT hand back a slot: the count is
-- completed_count (see reward_slots_used), which a missed user
-- never had.
--
-- A send to someone mid-attempt ('emailed' or 'started') only
-- bumps the counter and the timestamp: it must never knock a
-- user back to the start of a walkthrough they are part-way
-- through.
--
-- The reset would erase the fact that they ever finished, so
-- reward_claim_track counts completions separately in
-- completed_count, which no re-arm touches.
--
-- ORDER MATTERS: MariaDB evaluates ON DUPLICATE KEY UPDATE
-- assignments left to right, and each one sees the values
-- assigned before it. `status` is therefore assigned LAST, so
-- the `step` line above it still tests the OLD status.
-- =========================================================
DROP PROCEDURE IF EXISTS `reward_claim_emailed`$
CREATE PROCEDURE `reward_claim_emailed`(
  IN _uid VARCHAR(16),
  IN _campaign VARCHAR(64)
)
BEGIN
  INSERT INTO reward_claim (uid, campaign, status, emailed_count, last_emailed, ctime, mtime)
  VALUES (
    _uid,
    IFNULL(NULLIF(_campaign, ''), 'free-storage'),
    'emailed',
    1,
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  )
  ON DUPLICATE KEY UPDATE
    emailed_count = emailed_count + 1,
    last_emailed  = UNIX_TIMESTAMP(),
    step          = IF(status IN ('done', 'dropped', 'missed'), NULL, step),
    -- The re-arm starts a fresh attempt, so the previous attempt's click no
    -- longer counts: they have to follow the link again.
    clicked_at    = IF(status IN ('done', 'dropped', 'missed'), 0, clicked_at),
    status        = IF(status IN ('done', 'dropped', 'missed'), 'emailed', status),
    mtime         = UNIX_TIMESTAMP();
END $

DELIMITER ;
