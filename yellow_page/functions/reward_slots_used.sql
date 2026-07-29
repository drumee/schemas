DELIMITER $

-- =========================================================
-- reward_slots_used
--
-- How many of the claim-reward campaign's limited slots are
-- taken.
--
-- A slot is `completed_count > 0`, not `status = 'done'`: the
-- count has to survive a re-arm. reward_claim_emailed puts a
-- finished user back to 'emailed' when the campaign is
-- re-sent, so counting 'done' rows would silently HAND BACK
-- their slot and let the total rewarded drift past the limit.
-- completed_count is never reset, so one user is one slot, for
-- good, and a user who finishes a re-armed attempt does not
-- take a second one.
--
-- Derived rather than kept in a counter: reward_claim is the
-- only place a completion is recorded, so there is nothing to
-- drift out of step with.
--
-- A FUNCTION rather than a procedure because both callers want
-- one number: `await_func` unwraps a scalar, while a CALL's own
-- SELECT comes back as a raw multi-resultset that does not
-- parse into a row. Read by the desk gate (server-team
-- reward.get_state) and by the dashboard (analytics-server
-- reward_slots).
-- =========================================================
DROP FUNCTION IF EXISTS `reward_slots_used`$
CREATE FUNCTION `reward_slots_used`()
RETURNS INTEGER READS SQL DATA
BEGIN
  DECLARE _claimed INTEGER DEFAULT 0;

  SELECT COUNT(*) INTO _claimed FROM reward_claim WHERE completed_count > 0;

  RETURN _claimed;
END$

DELIMITER ;
