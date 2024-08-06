DELIMITER $



DROP PROCEDURE IF EXISTS `payment_status`$
  CREATE PROCEDURE `payment_status`(
    IN _entity_id VARCHAR(16),
    IN _subscription_id VARCHAR(30)
    )
  BEGIN
    DECLARE _status VARCHAR(30);

    SELECT 'unknown' INTO _status;

     SELECT  status  
      FROM 
      renewal_history s
     WHERE   entity_id =_entity_id AND 
      subscription_id = _subscription_id  
     ORDER BY ctime desc LIMIT 1 INTO _status;

    SELECT _status status, _entity_id entity_id , _subscription_id subscription_id;

  END $


DELIMITER ;

