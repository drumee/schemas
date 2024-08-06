DELIMITER $

 
--    used to get avaaialbe plans 
 DROP PROCEDURE IF EXISTS `plans_get`$
  CREATE PROCEDURE `plans_get`(
    IN _entity_id VARCHAR(16)
    )
  BEGIN

      SELECT 
        plan, 
        metadata,
        (
          SELECT 
           JSON_ARRAYAGG(
              JSON_OBJECT(
              'product_id' ,id,
              'period' ,  pck.period, 
              'product' , product,
              'plan', plan,
              'recurring', recurring,
              'price' , price,
              'offer_price', offer_price,
              'is_offer',   CASE WHEN pck.offer_price IS NULL THEN 0 ELSE 1 END ,
              'unit_price',IFNULL(pck.offer_price, pck.price) * CASE WHEN period = 'year' THEN 12.0 else 1.0 END *120/100) 
            )
        
        FROM
        yp.product pck 
        WHERE  pl.plan = pck.plan
        ) plan_detail
      FROM product pl WHERE is_active = 1  GROUP BY  plan;
  END $


DELIMITER ;

