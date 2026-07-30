DELIMITER $

-- =========================================================
-- reward_personal_eligible
--
-- Can this user hold the claim-reward prize?
--
-- The prize is a PERSONAL yp.quota entitlement (5 years of
-- unlimited storage, source='reward'). Every resolver is
-- tenant-first: when domain_id > 1 the ORGANISATION's row wins
-- and a personal payer row is never read. So a reward written
-- for a user covered by an org entitlement is not a smaller
-- prize, it is no prize at all -- a row that looks like an
-- entitlement and changes nothing.
--
-- ONE function, three callers, because the rule was briefly
-- written twice and the two copies immediately disagreed:
--
--   reward.get_state (server-team)  -- turns them away at the
--     gate, before Step 1, so nobody walks a three-step
--     walkthrough to be handed nothing
--   reward_claim_track              -- refuses the AWARD, so an
--     ineligible user does not consume one of the campaign's
--     limited places
--   reward_grant_storage            -- refuses the WRITE, the
--     backstop for a browser that was already open
--
-- The middle one is the one that was missing. The grant refused
-- while the award went through, so an org member could burn a
-- slot and receive nothing -- and because reward_slots_used
-- counts completed_count, that place was gone for good.
--
-- The org test is the same INNER JOIN yp.organisation the
-- resolvers use to PICK the org row, rather than a bare
-- `domain_id > 1`: a domain routinely holds rows that are not
-- the organisation's (org_provision re-keys the payer's
-- personal row onto it), so "is in a domain" and "is covered by
-- an org entitlement" are different questions and only the
-- second one matters here.
--
-- A FUNCTION so callers can use it in an expression --
-- reward_claim_track needs it inside an IF, and the server
-- reads it with `SELECT reward_personal_eligible(?)`, the same
-- shape it already uses for reward_slots_used().
-- =========================================================
DROP FUNCTION IF EXISTS `reward_personal_eligible`$
CREATE FUNCTION `reward_personal_eligible`(
  _uid VARCHAR(16)
)
RETURNS INTEGER READS SQL DATA
BEGIN
  DECLARE _domain_id INT(11) UNSIGNED DEFAULT NULL;

  SET _domain_id = (SELECT domain_id FROM drumate WHERE id = _uid LIMIT 1);

  -- No such user. Not eligible, and not an error: the campaign can only ever
  -- be claimed by a signed-in caller, so this is a poke at the endpoint.
  IF _domain_id IS NULL THEN
    RETURN 0;
  END IF;

  IF _domain_id > 1 AND EXISTS (
    SELECT 1 FROM quota q
     INNER JOIN organisation o
        ON o.domain_id = q.domain_id AND o.id = q.payer_id
     WHERE q.domain_id = _domain_id
  ) THEN
    RETURN 0;
  END IF;

  RETURN 1;
END$

DELIMITER ;
