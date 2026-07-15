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

  SELECT _entity_id AS entity_id, ROW_COUNT() AS cleared;
END $

DELIMITER ;
