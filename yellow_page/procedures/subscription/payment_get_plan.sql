DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_plan`$
CREATE PROCEDURE `payment_get_plan`(
  IN _plan_code VARCHAR(30) CHARACTER SET ascii,
  IN _period VARCHAR(8) CHARACTER SET ascii,
  IN _currency CHAR(3) CHARACTER SET ascii
)
BEGIN
  SELECT plan_code, entity_type, period, currency, stripe_price_id, stripe_product_id, quota
  FROM yp.plan
  WHERE plan_code = _plan_code AND period = _period AND currency = _currency AND active = 1
  LIMIT 1;
END $
DELIMITER ;
