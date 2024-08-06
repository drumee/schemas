DELIMITER $



--   for job
  DROP PROCEDURE IF EXISTS `renewal_expiry_update`$
  CREATE PROCEDURE `renewal_expiry_update`(
    _entity_id VARCHAR(16),
    _subscription_id VARCHAR(30), 
    _next_action VARCHAR(16)
    )
  BEGIN
  
    UPDATE renewal SET  metadata = JSON_SET(`metadata`, CONCAT("$.",_next_action, '.on'), 0)
    WHERE entity_id  = _entity_id AND 
    subscription_id = _subscription_id AND 
    next_action = _next_action; 

  END $

DELIMITER ;

