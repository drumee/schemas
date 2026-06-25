DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_addon`$
CREATE PROCEDURE `payment_get_addon`(
  IN _price_id VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  -- The storage add-on (entity_type='addon') for a given Stripe price id, with
  -- the disk it grants. Empty result => the price is not an add-on (base plan).
  SELECT plan_code, JSON_VALUE(quota, '$.disk') AS disk
  FROM yp.plan
  WHERE stripe_price_id = _price_id AND entity_type = 'addon' AND active = 1
  LIMIT 1;
END $
DELIMITER ;
