DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_payer`$
CREATE PROCEDURE `payment_get_payer`(
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT d.id, d.email, d.fullname, d.domain_id, s.customer_id
  FROM yp.drumate d
  LEFT JOIN yp.subscription_new s ON s.entity_id = d.id
  WHERE d.id = _uid
  LIMIT 1;
END $
DELIMITER ;
