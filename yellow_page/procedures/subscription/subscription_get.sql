DELIMITER $


  DROP PROCEDURE IF EXISTS `subscription_get`$
  CREATE PROCEDURE `subscription_get`(
    IN _entity_id VARCHAR(16)
    
    )
  BEGIN
  
    SELECT entity_id,subscription_id,customer_id,
            plan ,period,recurring, price,offer_price,status,ctime 
    FROM
      subscription_new WHERE entity_id = _entity_id; 

  END $


DELIMITER ;

