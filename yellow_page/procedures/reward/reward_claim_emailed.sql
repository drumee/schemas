DELIMITER $

-- =========================================================
-- reward_claim_emailed
--
-- Log that the claim-reward campaign mail was accepted for
-- this user, seeding the top of the funnel. Called once per
-- recipient by analytics-server claim_reward().
--
-- A re-send only bumps the counter and the timestamp: `status`
-- and `step` are deliberately NOT touched, so mailing someone
-- a second time can never reset a user who already started,
-- dropped or completed the flow.
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
    mtime         = UNIX_TIMESTAMP();
END $

DELIMITER ;
