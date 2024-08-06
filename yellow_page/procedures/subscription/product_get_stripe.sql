DELIMITER $

   
  --  USED for initialize the stripe 
DROP PROCEDURE IF EXISTS `product_get_stripe`$
CREATE PROCEDURE `product_get_stripe`()
BEGIN
        SELECT 
        id, 
        product,
        plan,
        period,
        recurring,
        price,
        offer_price ,
        ROUND(CASE WHEN period = 'year' THEN IFNULL(offer_price,price ) * 12.0  ELSE IFNULL(offer_price,price ) *1.0 END *120/100, 2)  unit_price,
        (CASE WHEN period = 'year' THEN IFNULL(offer_price,price ) * 1200.0  ELSE IFNULL(offer_price,price ) *100.0 END*120/100)  stripe_unit_price
    FROM yp.product 
    WHERE plan = 'Pro' AND 
        recurring = 1 AND 
        is_active=1;   
END $
DELIMITER ;

