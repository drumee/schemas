-- File: schemas/drumate/procedures/mfs_get_unread_count.sql
-- Purpose: Get count of unread notifications for current user

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_unread_count`$

CREATE PROCEDURE `mfs_get_unread_count`(
  IN _user_id VARCHAR(16)
)
BEGIN
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;
  DECLARE _record_exists INT DEFAULT 0;
  
  SELECT COUNT(*) INTO _record_exists
  FROM mfs_ack
  WHERE user_id = _user_id;
  
  -- If no record exists (old users or bug), initialize it
  IF _record_exists = 0 THEN
    -- Set to current max to avoid showing all old notifications
    SELECT IFNULL(MAX(id), 0) INTO _last_read_id
    FROM yp.mfs_changelog;
    
    INSERT INTO mfs_ack (user_id, last_read_id, mtime)
    VALUES (_user_id, _last_read_id, UNIX_TIMESTAMP());
    
    SELECT 0 AS unread_count;
  ELSE
    -- Normal flow: get last_read_id
    SELECT IFNULL(last_read_id, 0) INTO _last_read_id
    FROM mfs_ack
    WHERE user_id = _user_id;
    
    -- Create temp table for accessible hubs
    DROP TABLE IF EXISTS _user_accessible_hubs;
    CREATE TEMPORARY TABLE _user_accessible_hubs (
      hub_id VARCHAR(16) CHARACTER SET ascii PRIMARY KEY
    );

    -- Insert hubs user owns
    INSERT INTO _user_accessible_hubs (hub_id)
    SELECT id FROM yp.hub WHERE owner_id = _user_id;
    
    -- Insert hubs user is member of
    INSERT IGNORE INTO _user_accessible_hubs (hub_id)
    SELECT entity_id 
    FROM permission 
    WHERE resource_id = _user_id 
      AND expiry_time > UNIX_TIMESTAMP();
    
    -- Insert user's personal space
    INSERT IGNORE INTO _user_accessible_hubs (hub_id)
    VALUES (_user_id);
    
    -- Count unread from accessible hubs only
    SELECT COUNT(*) AS unread_count
    FROM yp.mfs_changelog c
    INNER JOIN _user_accessible_hubs ah ON c.hub_id = ah.hub_id
    WHERE c.id > _last_read_id
      AND c.uid != _user_id;
    
    DROP TABLE IF EXISTS _user_accessible_hubs;
  END IF;
  
END$

DELIMITER ;