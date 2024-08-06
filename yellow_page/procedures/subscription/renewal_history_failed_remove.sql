DELIMITER $




  DROP PROCEDURE IF EXISTS `renewal_history_failed_remove`$
  CREATE PROCEDURE `renewal_history_failed_remove`(
    IN _entity_id VARCHAR(16),
    IN _subscription_id VARCHAR(30)
    )
  BEGIN
  
     DELETE  FROM renewal_history 
     WHERE   entity_id =_entity_id AND 
     subscription_id = _subscription_id AND status = 'open';

  END $

DELIMITER ;

