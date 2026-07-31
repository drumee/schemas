DELIMITER $

DROP PROCEDURE IF EXISTS `payment_clear_entitlement`$
CREATE PROCEDURE `payment_clear_entitlement`(
  IN _entity_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- Remove an entity's Stripe entitlement row from yp.quota entirely, so
  -- disk_limit falls through to the next tier.
  --
  -- Used on ORG (team) cancellation: an org entitlement row is keyed by the
  -- org id (payer_id) + the org's domain_id, and disk_limit tier-2 cascades it
  -- to every member of that domain. Applying a "free" plan to an org instead
  -- (payment_apply_entitlement(org,'free',...)) is a data-lockout bug: there is
  -- no ('free','org') plan row, so it falls back to 50GB * 0 seats = disk 0 and
  -- locks out every member. Deleting the row lets each member fall back to the
  -- per-user free tier (tier-4) — the correct "team downgraded to free" state.
  --
  -- Never touches the seeded free fallback row (payer_id 'ffffffffffffffff').
  DELETE FROM yp.quota
   WHERE payer_id = _entity_id
     AND payer_id <> 'ffffffffffffffff';

  SET @_cleared = ROW_COUNT();

  -- RE-MATERIALISE A CLAIM-REWARD ENTITLEMENT, if this entity ever won one.
  --
  -- The reward is 5 years of unlimited storage, written as a source='reward'
  -- row. Subscribing OVERWRITES that row with the Stripe entitlement, which is
  -- correct — paid outranks a free reward — but the DELETE above then drops the
  -- user to the 5 GB free tier rather than back to the reward they still hold.
  -- Cancelling a subscription would silently cost them the prize.
  --
  -- Safe for everyone else: reward_grant_storage writes nothing unless
  -- yp.reward_claim shows a completion, and it recomputes period_end from
  -- completed_at, so this restores the REMAINDER of the original term rather
  -- than handing out five fresh years for cancelling.
  --
  -- Only for individuals. An org cancellation passes the ORGANISATION id, which
  -- has no reward_claim row and no drumate row, so the call would be a no-op —
  -- but the intent of the org path is that every member falls to their own
  -- per-user tier, and reaching into it here would blur that.
  IF EXISTS (SELECT 1 FROM yp.drumate WHERE id = _entity_id) THEN
    CALL reward_grant_storage(_entity_id);
  END IF;

  SELECT _entity_id AS entity_id, @_cleared AS cleared;
END $

DELIMITER ;
