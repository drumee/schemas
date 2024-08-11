
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_generate`$
CREATE PROCEDURE `licence_generate`(
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

-- DROP PROCEDURE IF EXISTS `licence_generate`$
-- CREATE PROCEDURE `licence_generate`(
--  IN  _data JSON
-- )
-- BEGIN

--   DECLARE  _domain  varchar(1000);
--   DECLARE  _email varchar(1000) CHARACTER SET ascii;
--   DECLARE  _key VARCHAR(64) CHARACTER SET ascii;
--   DECLARE  _status VARCHAR(64) CHARACTER SET ascii;
--   DECLARE  _uid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE  _cid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE  _lid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE  _fid VARCHAR(16) CHARACTER SET ascii;
--   DECLARE  _company_id VARCHAR(16) CHARACTER SET ascii;
--   DECLARE  _customer_id VARCHAR(16) CHARACTER SET ascii;
--   DECLARE  _signature VARCHAR(16) CHARACTER SET ascii;
--   DECLARE _ctime int(11) unsigned;
--   DECLARE _rollback BOOLEAN DEFAULT 0;  
--   DECLARE _number_of_bays INT DEFAULT 0;  


--   SELECT JSON_VALUE( _data, '$.domain_name')  INTO _domain ;
--   SELECT JSON_VALUE( _data, '$.email')  INTO _email;
--   SELECT JSON_VALUE( _data, '$.key')  INTO _key;
--   SELECT JSON_VALUE( _data, '$.reseller_id')  INTO _domain ;
--   SELECT JSON_VALUE( _data, '$.customer_id')  INTO _customer_id ;
--   SELECT JSON_VALUE( _data, '$.company_id')  INTO _company_id ;
--   SELECT JSON_VALUE( _data, '$.number_of_bays')  INTO _number_of_bays;
--   SELECT JSON_VALUE( _data, '$.signature')  INTO _signature;
--   SELECT IFNULL(JSON_VALUE( _data, '$.status'), 'trial')  INTO _status;

--   SELECT id, email FROM customer WHERE email=_email OR customer_id=_customer_id 
--     INTO _customer_id, _email;

--   IF _customer_id IS NULL THEN
--     SELECT yp.uniqueId() INTO _customer_id;
--     INSERT INTO customer(id, email, company_id) SELECT (_customer_id, _email, _email);
--   END IF;

--   INSERT INTO licence (
--     `id`,
--     `key`,
--     `domain`,
--     `customer_id`,
--     `reseller_id`,
--     `number_of_bays`,
--     `start`,
--     `end`,
--     `status`,
--     `signature`)
--   SELECT 
--     yp.uniqueId(), 
--     _key, 
--     _domain, 
--     _customer_id, 
--     _reseller_id, 
--     _number_of_bays, 
--     UNIX_TIMESTAMP(),
--     UNIX_TIMESTAMP(), 
--     _status, 
--     _signature; 

--   SELECT * FROM licence WHERE `key` = _key;
  
-- END$


DELIMITER ;

