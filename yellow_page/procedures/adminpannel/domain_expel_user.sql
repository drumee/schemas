DELIMITER $

DROP PROCEDURE IF EXISTS `domain_expel_user`$

CREATE PROCEDURE `domain_expel_user`(
  IN _user_id VARCHAR(16),
  IN _source_dom_id VARCHAR(16)
)
main_proc: BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(20);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _hub_domain_id INT(11) UNSIGNED;
  DECLARE _user_privilege INT(4) UNSIGNED;
  DECLARE _new_owner_id VARCHAR(16);
  DECLARE _user_db VARCHAR(50);
  DECLARE _new_owner_db VARCHAR(50);
  DECLARE _hub_count INT DEFAULT 0;
  DECLARE _current_idx INT DEFAULT 0;
  DECLARE _finished INTEGER DEFAULT 0;

  DECLARE dbcursor CURSOR FOR SELECT hub_id, hub_db, owner_id, domain_id FROM _temp_hubs;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

  SELECT db_name FROM yp.entity WHERE id = _user_id INTO _user_db;
  
  IF _user_db IS NULL THEN
    SELECT 'ERROR' AS status, 'User database not found' AS message;
    LEAVE main_proc;
  END IF;

  -- Find new owner
  SELECT uid, db_name FROM privilege p INNER JOIN entity e ON p.uid=e.id
  WHERE domain_id = _source_dom_id 
    AND privilege >= 63 
    AND uid != _user_id
  ORDER BY privilege DESC 
  LIMIT 1
  INTO _new_owner_id, _new_owner_db;
  
  DROP TEMPORARY TABLE IF EXISTS _temp_hubs;
  CREATE TEMPORARY TABLE _temp_hubs (
    hub_id VARCHAR(16),
    hub_db VARCHAR(20),
    owner_id VARCHAR(16),
    domain_id VARCHAR(16),
    PRIMARY KEY (`hub_id`)
  );

  -- Get user's hubs
  SET @sql = CONCAT(
    "INSERT INTO _temp_hubs (hub_id, hub_db, owner_id, domain_id) ",
    "SELECT m.id, e.db_name, h.owner_id, h.domain_id ",
    "FROM `", _user_db, "`.media m ",
    "INNER JOIN yp.entity e ON e.id = m.id ",
    "INNER JOIN yp.hub h ON h.id = m.id ",
    "WHERE m.category = 'hub'"
  );
  
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  IF _new_owner_id IS NULL THEN 
    SELECT 1 INTO _finished;
  ELSE
    UPDATE privilege SET domain_id=1 WHERE uid=_user_id;
  -- Update drumate domain_id
    UPDATE drumate SET domain_id = 1 WHERE id = _user_id;
  
  -- Update drumate profile to set category = "free"
    UPDATE yp.drumate 
    SET profile = JSON_SET(profile, '$.category', 'free', '$.profile_type', 'free')
    WHERE id = _user_id;
  
    -- Update entity dom_id
    UPDATE entity SET dom_id = 1 WHERE id = _user_id;
    
    -- Update vhost dom_id
    UPDATE yp.vhost SET dom_id = 1 WHERE id = _user_id;
  END IF;

  OPEN dbcursor;
   STARTLOOP: LOOP
    FETCH dbcursor INTO _hub_id, _hub_db, _owner_id, _hub_domain_id;
    IF _finished = 1 THEN 
      LEAVE STARTLOOP;
    END IF;

    IF _hub_domain_id = _source_dom_id THEN
        SET @s3 = CONCAT("DELETE FROM `", _user_db, "`.media WHERE id = ", QUOTE(_hub_id));
        PREPARE stmt FROM @s3;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @s4 = CONCAT("DELETE FROM `", _user_db, "`.permission WHERE resource_id = ", QUOTE(_hub_id));
        PREPARE stmt4 FROM @s4;
        EXECUTE stmt4;
        DEALLOCATE PREPARE stmt4;

        SET @s5 = CONCAT("DELETE FROM `", _hub_db, "`.permission WHERE entity_id = ", QUOTE(_user_id));
        PREPARE stmt5 FROM @s5;
        EXECUTE stmt5;
        DEALLOCATE PREPARE stmt5;

      IF _owner_id=_user_id THEN
        SET @s6 = CONCAT("CALL `", _new_owner_db, "`.join_hub(", QUOTE(_hub_id), ")");
        SELECT @s6;
        PREPARE stmt FROM @s6;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @s7 = CONCAT("CALL `", _hub_db, "`.permission_grant('*', '*', 0, ", 63, ", 'system', '')");
        SELECT @s7;
        PREPARE stmt FROM @s7;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
    END IF;
  END LOOP STARTLOOP;

  
  DROP TEMPORARY TABLE IF EXISTS _temp_hubs;
  
  SELECT 
    _user_id AS user_id,
    1 AS dest_domain_id,
    _source_dom_id AS src_domain_id,
    'free' AS new_category,
    _new_owner_id AS dest_owner,
    'expelled' AS status;
END$

DELIMITER ;