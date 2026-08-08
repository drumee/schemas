DELIMITER $

-- =========================================================
-- reward_claim_emailed
--
-- Log that the claim-reward campaign mail was accepted for
-- this user, seeding the top of the funnel. Called once per
-- recipient by analytics-server claim_reward().
--
-- A send to someone whose previous attempt ENDED (done,
-- dropped, missed or failed) RE-ARMS them: the row goes back
-- to 'emailed' with no step, so the desk gate — which now asks
-- the server rather than the browser — offers the flow again.
-- Re-sending the mail is therefore a real reset, with no
-- localStorage surgery.
--
-- 'dropped' belongs in that set even though it is the one
-- status the user chose deliberately. Dropping answers THIS
-- campaign; mailing them again is a new offer, and an admin who
-- re-sends is asking for exactly that. It is also the only way
-- back for someone who pressed "Drop anyway" by mistake, since
-- the gate will not otherwise open for them again.
--
-- 'missed' belongs in that set so raising the slot limit and
-- mailing again genuinely re-opens the flow for the people who
-- were turned away. It does NOT hand back a slot: the count is
-- completed_count (see reward_slots_used), which a missed user
-- never had.
--
-- 'left' DOES NOT belong in it, and this is the one that
-- changed. While the accidental exit was terminal it did; now
-- that it means "went away without telling us" it is a
-- MID-ATTEMPT state — it sits in reward.get_state's OPEN set, so
-- a user who left is already eligible and already resumes from
-- their step. Re-arming them would be a downgrade dressed as a
-- favour: it nulls the step they would have resumed at, zeroes
-- clicked_at, and drops them to 'emailed', which is NOT in OPEN
-- — so a user who could have carried on where they left off must
-- instead go and find the new mail and click it again. A re-send
-- must never take access away from someone who already had it.
--
-- A send to someone mid-attempt ('emailed', 'clicked',
-- 'started' or 'left') only bumps the counter and the
-- timestamp: it must never knock a user back to the start of a
-- walkthrough they are part-way through.
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
    -- The address works again, so the last refusal is history. Left in place it
    -- would keep an old "No such mailbox" on the row of someone the campaign
    -- has since reached, which reads as a live problem.
    failed_at     = 0,
    last_error    = NULL,
    step          = IF(status IN ('done', 'dropped', 'missed', 'failed'), NULL, step),
    -- The re-arm starts a fresh attempt, so the previous attempt's click no
    -- longer counts: they have to follow the link again.
    clicked_at    = IF(status IN ('done', 'dropped', 'missed', 'failed'), 0, clicked_at),
    -- 'failed' joins the re-armed set: a row only reaches it by never having
    -- been delivered to, so a send that IS accepted puts the user at the top of
    -- the funnel for the first time rather than leaving them marked undeliverable.
    status        = IF(status IN ('done', 'dropped', 'missed', 'failed'), 'emailed', status),
    mtime         = UNIX_TIMESTAMP();
END $

DELIMITER ;
