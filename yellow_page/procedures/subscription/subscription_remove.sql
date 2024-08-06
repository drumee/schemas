DELIMITER $




  -- delete the subscription 
  DROP PROCEDURE IF EXISTS `subscription_remove`$
  CREATE PROCEDURE `subscription_remove`(
    IN _entity_id VARCHAR(16),
    IN _subscription_id VARCHAR(30)
    )
  BEGIN
  
     DELETE  FROM subscription_new 
     WHERE   entity_id =_entity_id AND 
     subscription_id = _subscription_id;

  END $


DELIMITER ;

