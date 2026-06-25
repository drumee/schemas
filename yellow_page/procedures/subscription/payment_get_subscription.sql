DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_subscription`$
CREATE PROCEDURE `payment_get_subscription`(
  IN _entity_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT s.entity_id, s.subscription_id, s.customer_id, s.plan, s.period, s.recurring,
         s.price, s.offer_price, s.status, s.ctime,
         q.plan AS entitlement_plan, JSON_VALUE(q.quota,'$.disk') AS disk_limit, q.period_end
  FROM yp.subscription_new s
  LEFT JOIN yp.quota q ON q.payer_id = s.entity_id
  WHERE s.entity_id = _entity_id;
END $
DELIMITER ;
