DELIMITER $



  --   used in web hook to update subscription_new table
  DROP PROCEDURE IF EXISTS `subscription_update`$
  CREATE PROCEDURE `subscription_update`(
    IN _entity_id VARCHAR(16),
    IN _customer_id VARCHAR(30),
    IN _subscription_id VARCHAR(30),
    IN _plan varchar(30) ,
    IN _period varchar(30) ,
    IN _recurring  INT(11) , 
    IN _price float,
    IN _offer_price  float,
    IN _status varchar(30) 
    )
  BEGIN
  
    INSERT INTO subscription_new 
      (entity_id,subscription_id,customer_id,
            plan ,period,recurring, price,offer_price,status,ctime)
    SELECT  _entity_id,_subscription_id,_customer_id,
            _plan ,_period,_recurring, _price,_offer_price,_status, UNIX_TIMESTAMP()
    ON DUPLICATE KEY UPDATE
        plan =_plan,
        period =_period, 
        recurring =_recurring,
        price =_price,
        offer_price =_offer_price,
        status =_status,
        ctime = UNIX_TIMESTAMP();

  END $


DELIMITER ;

