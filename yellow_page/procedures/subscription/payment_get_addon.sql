DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_addon`$
CREATE PROCEDURE `payment_get_addon`(
  IN _price_id VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  -- The add-on (entity_type='addon') for a given Stripe price id, with what it
  -- grants: disk (storage_* bundles) and/or seat (pro_seat extra seats).
  -- Empty result => the price is not an add-on (base plan).
  SELECT plan_code, JSON_VALUE(quota, '$.disk') AS disk, JSON_VALUE(quota, '$.seat') AS seat
  FROM yp.plan
  WHERE stripe_price_id = _price_id AND entity_type = 'addon' AND active = 1
  LIMIT 1;
END $
DELIMITER ;
