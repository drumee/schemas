DELIMITER $



--   used for new,update, proration 
 DROP PROCEDURE IF EXISTS `product_get`$
  CREATE PROCEDURE `product_get`(
    IN _plan  varchar(30) CHARACTER SET ascii,
    IN _period varchar(30) CHARACTER SET ascii,
    IN _recurring  int
    )
  BEGIN

    SELECT 
    id, 
    product,
    plan,
    period,
    recurring,
    price,
    offer_price ,
    case WHEN period = 'year' THEN IFNULL(offer_price,price ) * 12.0  ELSE IFNULL(offer_price,price ) *1.0 END *120/100 unit_price,
    case WHEN period = 'year' THEN IFNULL(offer_price,price ) * 1200.0  ELSE IFNULL(offer_price,price ) *100.0 END *120/100 stripe_unit_price
    FROM yp.product 
    WHERE plan = _plan AND 
      period = _period AND 
      recurring = _recurring AND 
      is_active=1;
  END $

 
DELIMITER ;

