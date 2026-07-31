DELIMITER $

-- =========================================================
-- reward_claim_failed
--
-- Record that the campaign mail could NOT be delivered to this
-- user, and why. Called once per rejected address by
-- analytics-server claim_reward(), as the counterpart to
-- reward_claim_emailed.
--
-- The funnel used to have no way to say this. A send that the
-- MTA refused left either nothing at all or — worse — an
-- 'emailed' row, so a user who never received anything sat in
-- the dashboard next to users who did, and "mailed and never
-- came" swallowed "never mailed at all". They need different
-- answers: one is a person who ignored the offer, the other is
-- an address to fix.
--
-- STATUS IS ONLY DEMOTED FROM THE TOP OF THE FUNNEL. A user who
-- has clicked, started, dropped, missed or completed keeps that
-- status: those record what they DID, and a later bounced
-- re-send does not undo it. Only a row that is new, still
-- 'emailed' (mailed, no response yet) or already 'failed' can
-- become 'failed'.
--
-- The error is recorded either way, including for a user
-- mid-flow or done — an address that has started bouncing is
-- worth seeing whatever the funnel says about them.
--
-- emailed_count and last_emailed are deliberately NOT touched:
-- they count mail the MTA ACCEPTED, and this is the case where
-- it did not. Bumping them here would inflate the campaign's
-- reach by exactly the addresses it failed to reach.
--
-- ORDER MATTERS: MariaDB evaluates ON DUPLICATE KEY UPDATE
-- assignments left to right, and each one sees the values
-- assigned before it. `status` is assigned LAST so it is the
-- only line that has to reason about the old status.
-- =========================================================
DROP PROCEDURE IF EXISTS `reward_claim_failed`$
CREATE PROCEDURE `reward_claim_failed`(
  IN _uid VARCHAR(16),
  IN _campaign VARCHAR(64),
  IN _reason VARCHAR(190)
)
BEGIN
  INSERT INTO reward_claim (uid, campaign, status, failed_at, last_error, ctime, mtime)
  VALUES (
    _uid,
    IFNULL(NULLIF(_campaign, ''), 'free-storage'),
    'failed',
    UNIX_TIMESTAMP(),
    NULLIF(_reason, ''),
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  )
  ON DUPLICATE KEY UPDATE
    failed_at  = UNIX_TIMESTAMP(),
    last_error = NULLIF(_reason, ''),
    status     = IF(status IN ('emailed', 'failed'), 'failed', status),
    mtime      = UNIX_TIMESTAMP();
END $

DELIMITER ;
