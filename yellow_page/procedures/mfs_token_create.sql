-- File: schemas/yellow_page/procedures/mfs_token_create.sql
-- Purpose: Create a new MFS export token with pseudo entity and permissions

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_token_create`$

CREATE PROCEDURE `mfs_token_create`(
  IN _hub_id VARCHAR(16),
  IN _node_id VARCHAR(16),
  IN _user_id VARCHAR(16),
  IN _expiry_hours INT,
  IN _permission TINYINT(4)
)
BEGIN
  DECLARE _token VARCHAR(64);
  DECLARE _pseudo_entity VARCHAR(16);
  DECLARE _expiry_time INT UNSIGNED DEFAULT 0;
  DECLARE _ctime INT UNSIGNED;
  DECLARE _hub_db VARCHAR(80);
  DECLARE _user_permission TINYINT(4);
  DECLARE _sp_call TEXT;
  
  SELECT UNIX_TIMESTAMP() INTO _ctime;
  
  IF _expiry_hours > 0 THEN
    SELECT UNIX_TIMESTAMP(TIMESTAMPADD(HOUR, _expiry_hours, FROM_UNIXTIME(_ctime))) INTO _expiry_time;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM yp.entity WHERE id = _user_id) THEN
    SELECT 1 AS failed, 'User not found' AS reason;
    LEAVE BEGIN;
  END IF;
  
  SELECT db_name FROM yp.entity WHERE id = _hub_id INTO _hub_db;
  IF _hub_db IS NULL THEN
    SELECT 1 AS failed, 'Hub not found' AS reason;
    LEAVE BEGIN;
  END IF;
  
  -- Check user permission on the node (must be admin or owner)
  SET @perm_check = CONCAT('SELECT ', _hub_db, '.user_permission(?, ?) INTO @user_perm');
  PREPARE stmt FROM @perm_check;
  EXECUTE stmt USING _user_id, _node_id;
  DEALLOCATE PREPARE stmt;
  
  SELECT @user_perm INTO _user_permission;
  
  -- Admin permission is 15 (1111 in binary: read, write, delete, admin)
  -- Owner permission is 63 (all permissions)
  IF _user_permission < 15 THEN
    SELECT 1 AS failed, 'Insufficient permission. User must be admin or owner' AS reason;
    LEAVE BEGIN;
  END IF;
  
  -- Generate unique token (UUID without hyphens)
  SELECT REPLACE(UUID(), '-', '') INTO _token;
  
  -- Generate unique pseudo_entity ID (format: export_<first 8 chars of token>)
  SELECT CONCAT('export_', LEFT(_token, 8)) INTO _pseudo_entity;
  
  WHILE EXISTS (SELECT 1 FROM yp.pseudo_entity WHERE pseudo_entity = _pseudo_entity) DO
    SELECT REPLACE(UUID(), '-', '') INTO _token;
    SELECT CONCAT('export_', LEFT(_token, 8)) INTO _pseudo_entity;
  END WHILE;
  
  START TRANSACTION;
  
  INSERT INTO yp.pseudo_entity (pseudo_entity, uid, token, ctime)
  VALUES (_pseudo_entity, _user_id, _token, _ctime);
  
  INSERT INTO yp.mfs_token (token, hub_id, node_id, user_id, pseudo_entity_uid, expiry_time, ctime)
  VALUES (_token, _hub_id, _node_id, _user_id, _pseudo_entity, _expiry_time, _ctime);
  
  -- Grant permission in hub database
  -- Use resource_id = '*' to grant access to node and all descendants
  SET @grant_perm = CONCAT(
    'CALL ', _hub_db, '.permission_grant(?, ?, ?, ?, ?, ?)'
  );
  
  PREPARE stmt FROM @grant_perm;
  EXECUTE stmt USING 
    '*',                    -- resource_id: '*' means all nodes under the scope
    _pseudo_entity,         -- entity_id: pseudo entity
    _expiry_hours,          -- expiry_time in hours
    _permission,            -- permission level (2 = read)
    'api_export',           
    CONCAT('MFS Export Token - Created by user ', _user_id, ' for node ', _node_id);
  DEALLOCATE PREPARE stmt;
  
  IF @grant_result_failed = 1 THEN
    ROLLBACK;
    SELECT 1 AS failed, 'Failed to grant permission in hub database' AS reason;
    LEAVE BEGIN;
  END IF;
  COMMIT;
  
  SELECT 
    0 AS failed,
    _token AS token,
    _pseudo_entity AS pseudo_entity_uid,
    _hub_id AS hub_id,
    _node_id AS node_id,
    _expiry_time AS expiry_time,
    _ctime AS ctime,
    CONCAT('Token created successfully. Expires: ', 
      IF(_expiry_time = 0, 'Never', FROM_UNIXTIME(_expiry_time))) AS message;

END$

DELIMITER ;