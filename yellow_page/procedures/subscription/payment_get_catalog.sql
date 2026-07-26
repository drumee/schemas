DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_catalog`$
CREATE PROCEDURE `payment_get_catalog`(
  IN _currency CHAR(3) CHARACTER SET ascii,
  IN _entity_type VARCHAR(8) CHARACTER SET ascii
)
BEGIN
  -- NO price math. Price truth = Stripe; return stripe_price_id + granted quota.
  SELECT plan_code, entity_type, period, currency, stripe_price_id, stripe_product_id, quota, features
  FROM yp.plan
  WHERE active = 1
    AND (_currency IS NULL OR _currency = '' OR currency = _currency)
    AND (_entity_type IS NULL OR _entity_type = '' OR entity_type = _entity_type)
  ORDER BY FIELD(plan_code,'free','team','business'), FIELD(period,'free','month','year');
END $
DELIMITER ;
