-- File: schemas/yellow_page/procedures/mfs_token_revoke.sql
-- Purpose: Revoke an existing MFS export token and remove associated permissions

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_token_revoke`$

CREATE PROCEDURE `mfs_token_revoke`(
  IN _token VARCHAR(64),
  IN _user_id VARCHAR(16)
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _node_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(80);
  DECLARE _pseudo_entity VARCHAR(16);
  DECLARE _token_user_id VARCHAR(16);
  DECLARE _user_permission TINYINT(4);
  
  SELECT hub_id, node_id, user_id, pseudo_entity_uid 
  FROM yp.mfs_token 
  WHERE token = _token
  INTO _hub_id, _node_id, _token_user_id, _pseudo_entity;
  
  IF _hub_id IS NULL THEN
    SELECT 1 AS failed, 'Token not found' AS reason;
    LEAVE BEGIN;
  END IF;
  
  -- Get hub database name
  SELECT db_name FROM yp.entity WHERE id = _hub_id INTO _hub_db;
  IF _hub_db IS NULL THEN
    SELECT 1 AS failed, 'Hub not found' AS reason;
    LEAVE BEGIN;
  END IF;
  
  -- Check if user has permission to revoke (must be token creator or admin)
  IF _user_id != _token_user_id THEN
    SET @perm_check = CONCAT('SELECT ', _hub_db, '.user_permission(?, ?) INTO @user_perm');
    PREPARE stmt FROM @perm_check;
    EXECUTE stmt USING _user_id, _node_id;
    DEALLOCATE PREPARE stmt;
    
    SELECT @user_perm INTO _user_permission;
    
    -- Admin permission is 15 or higher
    IF _user_permission < 15 THEN
      SELECT 1 AS failed, 'Insufficient permission. Only token creator or admin can revoke' AS reason;
      LEAVE BEGIN;
    END IF;
  END IF;
  
  START TRANSACTION;
  
  SET @delete_perm = CONCAT(
    'DELETE FROM ', _hub_db, '.permission WHERE entity_id = ?'
  );
  PREPARE stmt FROM @delete_perm;
  EXECUTE stmt USING _pseudo_entity;
  DEALLOCATE PREPARE stmt;
  
  DELETE FROM yp.mfs_token WHERE token = _token;
  
  DELETE FROM yp.pseudo_entity WHERE pseudo_entity = _pseudo_entity AND token = _token;
  
  COMMIT;
  
  SELECT 
    0 AS failed,
    _token AS token,
    _hub_id AS hub_id,
    _node_id AS node_id,
    'Token revoked successfully' AS message;

END$

DELIMITER ;