DELIMITER $




  DROP PROCEDURE IF EXISTS `renewal_failed_remove`$
  CREATE PROCEDURE `renewal_failed_remove`(
    IN _entity_id VARCHAR(16),
    IN _subscription_id VARCHAR(30)
    )
  BEGIN
  
     DELETE  FROM renewal_failed 
     WHERE   entity_id =_entity_id AND 
     subscription_id = _subscription_id;

  END $


DELIMITER ;

