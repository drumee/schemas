
DELIMITER $

DROP PROCEDURE IF EXISTS `enterprise_create`$
CREATE PROCEDURE `enterprise_create`(
 IN _data JSON
)
BEGIN

  DECLARE  _id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _legal_id VARCHAR(128) CHARACTER SET ascii;
  DECLARE _bu_id VARCHAR(128) CHARACTER SET ascii;
  DECLARE _vat_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _legal_name VARCHAR(128);
  DECLARE _activity_id VARCHAR(128) CHARACTER SET ascii;
  DECLARE _activity_table VARCHAR(128) CHARACTER SET ascii;
  DECLARE _commercial_name VARCHAR(128);
  DECLARE _date_of_start VARCHAR(32) ;
  DECLARE _date_of_end VARCHAR(32);
  DECLARE _country_code VARCHAR(16);
  DECLARE _category VARCHAR(256);
  DECLARE _poc_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _st_of_start INT(11);
  DECLARE _st_of_end INT(11);
  DECLARE _workforce VARCHAR(16) CHARACTER SET ascii;

  SELECT JSON_VALUE(_data, '$.legal_id') INTO _legal_id ;
  SELECT JSON_VALUE(_data, '$.bu_id') INTO _bu_id ;
  SELECT JSON_VALUE(_data, '$.vat_id') INTO _vat_id;
  SELECT JSON_VALUE(_data, '$.legal_name') INTO _legal_name;
  SELECT JSON_VALUE(_data, '$.activity_id') INTO _activity_id ;
  SELECT JSON_VALUE(_data, '$.activity_table') INTO _activity_table;
  SELECT JSON_VALUE(_data, '$.commercial_name') INTO _commercial_name ;
  SELECT JSON_VALUE(_data, '$.date_of_start') INTO _date_of_start ;
  SELECT JSON_VALUE(_data, '$.date_of_end') INTO _date_of_end;
  SELECT JSON_VALUE(_data, '$.country_code') INTO _country_code;
  SELECT JSON_VALUE(_data, '$.category') INTO _category;
  SELECT JSON_VALUE(_data, '$.poc_id') INTO _poc_id;
  SELECT JSON_VALUE(_data, '$.workforce') INTO _workforce;

  SELECT yp.uniqueId() INTO _id;

  IF _date_of_start IS NOT NULL THEN 
    SELECT UNIX_TIMESTAMP(CAST(_date_of_start AS DATE)) INTO _st_of_start; 
  END IF;

  IF _date_of_end IS NOT NULL THEN 
    SELECT UNIX_TIMESTAMP(CAST(_date_of_end AS DATE)) INTO _st_of_end; 
  END IF;
  
  REPLACE INTO enterprise (
    id,
    legal_id,
    bu_id,
    vat_id,
    legal_name,
    activity_id,
    activity_table,
    commercial_name,
    date_of_start,
    date_of_end,
    country_code,
    category,
    workforce,
    poc_id)
  SELECT 
    _id,
    _legal_id,
    IFNULL(_bu_id, CONCAT("informal-", _id)),
    _vat_id,
    _legal_name,
    _activity_id,
    _activity_table,
    _commercial_name,
    _st_of_start,
    _st_of_end,
    _country_code,
    _category,
    _workforce,
    _poc_id;

 SELECT * FROM enterprise WHERE `id` = _id;
  
END$

DELIMITER ;