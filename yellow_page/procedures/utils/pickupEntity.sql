DELIMITER $

DROP PROCEDURE IF EXISTS `pickupEntity`$
CREATE PROCEDURE `pickupEntity`(
  IN _type VARCHAR(32),
  OUT _out_id VARCHAR(16),
  OUT _out_db VARCHAR(80)
)
BEGIN

  SELECT 
    id, 
    db_name
  FROM entity  
    WHERE `type`=_type
    AND area='pool' AND JSON_VALUE(settings, "$.pool_state")='clean' 
    ORDER BY RAND() LIMIT 1 INTO _out_id, _out_db;

END $


DELIMITER ;
