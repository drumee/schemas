DELIMITER $

DROP PROCEDURE IF EXISTS `move_user_to_free`$

CREATE PROCEDURE `move_user_to_free`(
  IN _user_id VARCHAR(16),
  IN _current_domain_id INT(11) UNSIGNED
)
main_proc: BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(20);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _hub_domain_id INT(11) UNSIGNED;
  DECLARE _user_privilege INT(4) UNSIGNED;
  DECLARE _new_owner_id VARCHAR(16);
  DECLARE _user_db VARCHAR(20);
  DECLARE _hub_count INT DEFAULT 0;
  DECLARE _current_idx INT DEFAULT 0;
  
  SELECT db_name FROM yp.entity WHERE id = _user_id INTO _user_db;
  
  IF _user_db IS NULL THEN
    SELECT 'ERROR' AS status, 'User database not found' AS message;
    LEAVE main_proc;
  END IF;
  
  -- Find new owner
  SELECT uid FROM yp.privilege 
  WHERE domain_id = _current_domain_id 
    AND privilege >= 63 
    AND uid != _user_id
  ORDER BY privilege DESC 
  LIMIT 1
  INTO _new_owner_id;
  
  DROP TEMPORARY TABLE IF EXISTS _temp_hubs;
  CREATE TEMPORARY TABLE _temp_hubs (
    idx INT AUTO_INCREMENT PRIMARY KEY,
    hub_id VARCHAR(16),
    hub_db VARCHAR(20),
    owner_id VARCHAR(16),
    hub_domain_id INT(11) UNSIGNED,
    user_privilege INT(4) UNSIGNED
  );
  
  -- Get user's hubs
  SET @sql = CONCAT(
    "INSERT INTO _temp_hubs (hub_id, hub_db, owner_id, user_privilege) ",
    "SELECT m.id, e.db_name, h.owner_id, p.permission ",
    "FROM `", _user_db, "`.media m ",
    "INNER JOIN `", _user_db, "`.permission p ON p.resource_id = m.id ",
    "INNER JOIN yp.entity e ON e.id = m.id ",
    "INNER JOIN yp.hub h ON h.id = m.id ",
    "WHERE m.category = 'hub'"
  );
  
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  
  -- Update hub_domain_id from yp.entity
  UPDATE _temp_hubs th
  INNER JOIN yp.entity e ON e.id = th.hub_id
  SET th.hub_domain_id = e.dom_id;
  
  SELECT COUNT(*) FROM _temp_hubs INTO _hub_count;
  
  -- Process each hub
  WHILE _current_idx < _hub_count DO
    SET _current_idx = _current_idx + 1;
    
    SELECT hub_id, hub_db, owner_id, hub_domain_id, user_privilege
    INTO _hub_id, _hub_db, _owner_id, _hub_domain_id, _user_privilege
    FROM _temp_hubs
    WHERE idx = _current_idx;
    
    -- If hub is in paid domain
    IF _hub_domain_id > 1 THEN
      
      -- If user is not owner, leave the hub
      IF _user_privilege < 63 THEN
        SET @s = CONCAT("CALL `", _user_db, "`.leave_hub(", QUOTE(_hub_id), ")");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
      -- If user is owner, transfer ownership
      ELSEIF _user_privilege >= 63 THEN
        
        IF _new_owner_id IS NOT NULL THEN
          UPDATE yp.hub SET owner_id = _new_owner_id WHERE id = _hub_id;
          
          SET @s2 = CONCAT(
            "INSERT INTO `", _hub_db, "`.permission (entity_id, resource_id, permission, expiry_time) ",
            "VALUES (", QUOTE(_new_owner_id), ", '*', 63, 0) ",
            "ON DUPLICATE KEY UPDATE permission = 63"
          );
          PREPARE stmt2 FROM @s2;
          EXECUTE stmt2;
          DEALLOCATE PREPARE stmt2;
          
          SET @s3 = CONCAT("CALL `", _user_db, "`.leave_hub(", QUOTE(_hub_id), ")");
          PREPARE stmt3 FROM @s3;
          EXECUTE stmt3;
          DEALLOCATE PREPARE stmt3;
        ELSE
          SET @s4 = CONCAT("CALL `", _user_db, "`.leave_hub(", QUOTE(_hub_id), ")");
          PREPARE stmt4 FROM @s4;
          EXECUTE stmt4;
          DEALLOCATE PREPARE stmt4;
        END IF;
        
      END IF;
      
    END IF;
    
  END WHILE;
  
  -- Update user's domain to Free
  UPDATE yp.privilege 
  SET domain_id = 1 
  WHERE uid = _user_id;
  
  -- Update drumate domain_id
  UPDATE yp.drumate 
  SET domain_id = 1 
  WHERE id = _user_id;
  
  -- Update drumate profile to set category = "free"
  UPDATE yp.drumate 
  SET profile = JSON_SET(profile, '$.category', 'free', '$.profile_type', 'free')
  WHERE id = _user_id;
  
  -- Update entity dom_id
  UPDATE yp.entity 
  SET dom_id = 1 
  WHERE id = _user_id;
  
  -- Update vhost dom_id
  UPDATE yp.vhost 
  SET dom_id = 1 
  WHERE id = _user_id;
  
  DROP TEMPORARY TABLE IF EXISTS _temp_hubs;
  
  SELECT 
    _user_id AS user_id,
    1 AS new_domain_id,
    'free' AS new_category,
    _new_owner_id AS transferred_to_owner,
    _hub_count AS total_hubs_processed,
    'moved_to_free' AS status;
    
END$

DELIMITER ;