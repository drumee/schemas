-- File: schemas/yellow_page/procedures/mfs_token_validate.sql
-- Purpose: Validate an MFS export token and return its details if valid

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_token_validate`$

CREATE PROCEDURE `mfs_token_validate`(
  IN _token VARCHAR(64)
)
BEGIN
  DECLARE _ctime INT UNSIGNED;
  DECLARE _expiry_time INT UNSIGNED;
  
  SELECT UNIX_TIMESTAMP() INTO _ctime;
  
  SELECT expiry_time FROM yp.mfs_token WHERE token = _token INTO _expiry_time;
  
  IF _expiry_time IS NULL THEN
    SELECT 1 AS failed, 'Token not found' AS reason, NULL AS token_data;
    LEAVE BEGIN;
  END IF;
  
  IF _expiry_time > 0 AND _expiry_time < _ctime THEN
    SELECT 1 AS failed, 'Token expired' AS reason, NULL AS token_data;
    LEAVE BEGIN;
  END IF;
  
  SELECT 
    0 AS failed,
    'Token is valid' AS message,
    t.token,
    t.hub_id,
    t.node_id,
    t.user_id,
    t.pseudo_entity_uid,
    t.expiry_time,
    t.ctime,
    e.db_name AS hub_db_name,
    CASE 
      WHEN t.expiry_time = 0 THEN 'never'
      ELSE 'active'
    END AS status
  FROM yp.mfs_token t
  INNER JOIN yp.entity e ON t.hub_id = e.id
  WHERE t.token = _token;

END$

DELIMITER ;