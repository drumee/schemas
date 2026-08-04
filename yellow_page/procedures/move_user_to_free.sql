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
  DECLARE _new_owner_id VARCHAR(16);
  DECLARE _new_owner_db VARCHAR(20);
  DECLARE _user_db VARCHAR(20);
  DECLARE _hub_count INT DEFAULT 0;
  DECLARE _source_hub_count INT DEFAULT 0;
  DECLARE _owned_source_hub_count INT DEFAULT 0;
  DECLARE _current_idx INT DEFAULT 0;
  DECLARE _next_serial INT(11) UNSIGNED DEFAULT 0;
  
  -- The move is limited to the target's current organisation. Require all
  -- three membership records to agree before changing any cross-db grants.
  SELECT e.db_name
  FROM yp.entity e
  INNER JOIN yp.drumate d ON d.id = e.id
  INNER JOIN yp.privilege p ON p.uid = e.id
  WHERE e.id = _user_id
    AND e.dom_id = _current_domain_id
    AND d.domain_id = _current_domain_id
    AND p.domain_id = _current_domain_id
  INTO _user_db;
  
  IF _user_db IS NULL THEN
    SELECT 'ERROR' AS status, 'NOT_IN_SOURCE_DOMAIN' AS code;
    LEAVE main_proc;
  END IF;
  
  -- Find a replacement owner in the source organisation before any member
  -- data is removed. A source-domain hub can never be left ownerless.
  SELECT p.uid, e.db_name
  FROM yp.privilege p
  INNER JOIN yp.entity e ON e.id = p.uid
  INNER JOIN yp.drumate d ON d.id = p.uid
  WHERE p.domain_id = _current_domain_id
    AND p.privilege >= 63
    AND p.uid != _user_id
    AND e.dom_id = _current_domain_id
    AND d.domain_id = _current_domain_id
    AND e.status = 'active'
  ORDER BY p.privilege DESC
  LIMIT 1
  INTO _new_owner_id, _new_owner_db;
  
  DROP TEMPORARY TABLE IF EXISTS _temp_hubs;
  CREATE TEMPORARY TABLE _temp_hubs (
    idx INT AUTO_INCREMENT PRIMARY KEY,
    hub_id VARCHAR(16),
    hub_db VARCHAR(20),
    owner_id VARCHAR(16),
    hub_domain_id INT(11) UNSIGNED
  );
  
  -- Get user's hubs
  SET @sql = CONCAT(
    "INSERT INTO _temp_hubs (hub_id, hub_db, owner_id) ",
    "SELECT m.id, e.db_name, h.owner_id ",
    "FROM `", _user_db, "`.media m ",
    "INNER JOIN `", _user_db, "`.permission p ON p.resource_id = m.id ",
    "AND p.entity_id = ", QUOTE(_user_id), " ",
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
  SELECT COUNT(*)
  FROM _temp_hubs
  WHERE hub_domain_id = _current_domain_id
  INTO _source_hub_count;
  SELECT COUNT(*)
  FROM _temp_hubs
  WHERE hub_domain_id = _current_domain_id
    AND owner_id = _user_id
  INTO _owned_source_hub_count;

  IF _owned_source_hub_count > 0
    AND (_new_owner_id IS NULL OR _new_owner_db IS NULL) THEN
    DROP TEMPORARY TABLE IF EXISTS _temp_hubs;
    SELECT 'ERROR' AS status, 'NO_REPLACEMENT_OWNER' AS code;
    LEAVE main_proc;
  END IF;
  
  -- Process each hub
  WHILE _current_idx < _hub_count DO
    SET _current_idx = _current_idx + 1;
    
    SELECT hub_id, hub_db, owner_id, hub_domain_id
    INTO _hub_id, _hub_db, _owner_id, _hub_domain_id
    FROM _temp_hubs
    WHERE idx = _current_idx;
    
    -- Only leave workspaces belonging to the organisation that initiated the
    -- removal. Membership in another organisation remains intact.
    IF _hub_domain_id = _current_domain_id THEN
      
      -- If user is not owner, leave the hub
      IF _owner_id != _user_id OR _owner_id IS NULL THEN
        -- 1. Delete from user's media table
        SET @s = CONCAT("DELETE FROM `", _user_db, "`.media WHERE id = ", QUOTE(_hub_id));
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- 2. Delete from user's permission table
        SET @s = CONCAT("DELETE FROM `", _user_db, "`.permission WHERE resource_id = ", QUOTE(_hub_id));
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- 3. Delete from hub's permission table
        SET @s = CONCAT("DELETE FROM `", _hub_db, "`.permission WHERE entity_id = ", QUOTE(_user_id));
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
      -- If user is owner, transfer ownership. The preflight above guarantees
      -- that a replacement owner exists for every source-domain owner hub.
      ELSE
        -- Prepare the replacement owner's desk-side membership before changing
        -- yp.hub.owner_id. A failure here leaves the current owner untouched.
        SET @s6 = CONCAT(
          "SELECT COUNT(*) INTO @_new_owner_has_hub FROM `", _new_owner_db,
          "`.media WHERE id = ", QUOTE(_hub_id)
        );
        PREPARE stmt6 FROM @s6;
        EXECUTE stmt6;
        DEALLOCATE PREPARE stmt6;
        IF @_new_owner_has_hub = 0 THEN
          SET @s7 = CONCAT(
            "CALL `", _new_owner_db, "`.join_hub(", QUOTE(_hub_id), ")"
          );
          PREPARE stmt7 FROM @s7;
          EXECUTE stmt7;
          DEALLOCATE PREPARE stmt7;
        END IF;

        -- The replacement owner needs a member-side permission as well; a
        -- hub-side grant alone leaves the workspace inaccessible in their desk.
        SET @s8 = CONCAT(
          "REPLACE INTO `", _new_owner_db, "`.permission VALUES(null, ",
          QUOTE(_hub_id), ", ", QUOTE(_new_owner_id), ", '---', 0, ",
          "UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 63, 'share')"
        );
        PREPARE stmt8 FROM @s8;
        EXECUTE stmt8;
        DEALLOCATE PREPARE stmt8;

        -- Grant full permission in the hub before finalising ownership.
        SET @s2 = CONCAT(
          "INSERT INTO `", _hub_db, "`.permission (entity_id, resource_id, permission, expiry_time) ",
          "VALUES (", QUOTE(_new_owner_id), ", '*', 63, 0) ",
          "ON DUPLICATE KEY UPDATE permission = 63, expiry_time = 0, ",
          "utime = UNIX_TIMESTAMP()"
        );
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;

        -- The unique (owner_id, serial) index collides if the new owner already
        -- has a hub with the same serial (their auto-created wicket sits at 0).
        -- Assign a fresh serial only after their access is ready.
        SELECT IFNULL(MAX(serial), -1) + 1
        FROM yp.hub WHERE owner_id = _new_owner_id
        INTO _next_serial;
        UPDATE yp.hub
        SET owner_id = _new_owner_id, serial = _next_serial
        WHERE id = _hub_id;

        -- Make the removed user leave the hub on both membership sides.
        SET @s3 = CONCAT("DELETE FROM `", _user_db, "`.media WHERE id = ", QUOTE(_hub_id));
        PREPARE stmt3 FROM @s3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;

        SET @s4 = CONCAT("DELETE FROM `", _user_db, "`.permission WHERE resource_id = ", QUOTE(_hub_id));
        PREPARE stmt4 FROM @s4;
        EXECUTE stmt4;
        DEALLOCATE PREPARE stmt4;

        SET @s5 = CONCAT("DELETE FROM `", _hub_db, "`.permission WHERE entity_id = ", QUOTE(_user_id));
        PREPARE stmt5 FROM @s5;
        EXECUTE stmt5;
        DEALLOCATE PREPARE stmt5;
        
      END IF;
      
    END IF;
    
  END WHILE;
  
  -- Update user's domain to Free (domain_id = 1)
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
    _source_hub_count AS total_hubs_processed,
    'moved_to_free' AS status;
    
END$

DELIMITER ;
