
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_create`$
CREATE PROCEDURE `licence_create`(
 IN _reseller_id VARCHAR(16) CHARACTER SET ascii,
 IN _customer_id VARCHAR(16) CHARACTER SET ascii,
 IN _signature TEXT CHARACTER SET ascii,
 IN _content JSON
)
BEGIN
  DECLARE _status VARCHAR(16) DEFAULT 'trial';
  DECLARE _id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _ctime INT(11) UNSIGNED;
  DECLARE _atime INT(11) UNSIGNED;
  
  SELECT JSON_VALUE(_content, '$.status') INTO _status ;

  IF _reseller_id IS NOT NULL THEN 
    SELECT yp.uniqueId() INTO _id;
    SELECT UNIX_TIMESTAMP() INTO _ctime;
    IF _status = 'active' THEN 
      SELECT UNIX_TIMESTAMP() INTO _atime;
    END IF;
    REPLACE INTO licence (
      `id`,
      `customer_id`,
      `reseller_id`,
      `content`,
      `ctime`,
      `atime`,
      `signature`)
    SELECT 
      _id,
      _customer_id,
      _reseller_id,
      _content,
      _ctime,
      _atime,
      _signature;
      
    SELECT * FROM customer WHERE `id` = _id;
  END IF;  

END$

DELIMITER ;