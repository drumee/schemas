
DELIMITER $

DROP PROCEDURE IF EXISTS `customer_create`$
CREATE PROCEDURE `customer_create`(
 IN _data JSON
)
BEGIN

  DECLARE  _ctime INT(11) UNSIGNED;
  DECLARE  _id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _email VARCHAR(256) CHARACTER SET ascii;
  DECLARE _bu_id VARCHAR(128) CHARACTER SET ascii;
  DECLARE _reseller_db VARCHAR(128) CHARACTER SET ascii;
  DECLARE _firstname VARCHAR(128);
  DECLARE _lastname VARCHAR(128);
  DECLARE _phone_area INTEGER;
  DECLARE _phone_number INTEGER;
  DECLARE _avatar VARCHAR(512);
  DECLARE _reseller_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _location longtext;
  DECLARE _table_exists INT DEFAULT 0;  

  SELECT JSON_VALUE(_data, '$.firstname') INTO _firstname ;
  SELECT JSON_VALUE(_data, '$.lastname') INTO _lastname ;
  SELECT JSON_VALUE(_data, '$.email') INTO _email ;
  SELECT JSON_VALUE(_data, '$.phone_area') INTO _phone_area ;
  SELECT JSON_VALUE(_data, '$.phone_number') INTO _phone_number ;
  SELECT JSON_VALUE(_data, '$.avatar') INTO _avatar;
  SELECT JSON_VALUE(_data, '$.bu_id') INTO _bu_id ;
  SELECT JSON_VALUE(_data, '$.location') INTO _location;

  SELECT yp.uniqueId() INTO _id;
  SELECT db_name, id FROM yp.entity WHERE db_name=DATABASE() 
    INTO _reseller_db, _reseller_id;

  IF _reseller_id IS NOT NULL THEN 
    SELECT count(*) FROM information_schema.TABLES WHERE 
      TABLE_SCHEMA=_reseller_db AND TABLE_NAME='customer' 
      INTO _table_exists;

    IF NOT _table_exists THEN
      SET @st = CONCAT("CREATE TABLE IF NOT EXISTS ", _reseller_db,
      ".customer LIKE licence.customer");
      PREPARE stmt FROM @st;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;

    SELECT UNIX_TIMESTAMP() INTO _ctime;
    REPLACE INTO customer (
      `id`,
      `ctime`,
      `firstname`,
      `lastname`,
      `email`,
      `phone_area`,
      `phone_number`,
      `avatar`,
      `bu_id`,
      `reseller_id`,
      `location`)
    SELECT 
      _id,
      _ctime,
      _firstname,
      _lastname,
      _email,
      _phone_area,
      _phone_number,
      _avatar,
      _bu_id,
      _reseller_id,
      _location;
      
    SELECT * FROM customer WHERE `id` = _id;
  END IF;  

END$

DELIMITER ;