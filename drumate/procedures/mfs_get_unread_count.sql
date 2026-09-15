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
    -- id IS NOT NULL: a FAILED workspace creation leaves a yp.hub row with
    -- owner_id set but id still NULL, and _user_accessible_hubs.hub_id is a
    -- PRIMARY KEY (implicitly NOT NULL) under STRICT_TRANS_TABLES. Without this
    -- guard ONE such row makes the whole procedure die with
    -- ERROR 1048 "Column 'hub_id' cannot be null" -- which silently emptied the
    -- notification feed and killed desk search for every affected user.
    -- The two INSERTs below have always been INSERT IGNORE; only this one was
    -- left unguarded.
    INSERT INTO _user_accessible_hubs (hub_id)
    SELECT id FROM yp.hub WHERE owner_id = _user_id AND id IS NOT NULL;
    
    -- Insert hubs user is member of
    INSERT IGNORE INTO _user_accessible_hubs (hub_id)
    SELECT entity_id 
    FROM permission 
    WHERE resource_id = _user_id 
      AND expiry_time > UNIX_TIMESTAMP();
    
    -- Insert user's personal space
    INSERT IGNORE INTO _user_accessible_hubs (hub_id)
    VALUES (_user_id);
    
    -- Count unread from accessible hubs only.
    --
    -- The mfs_dismissed LEFT JOIN is what makes this number agree with what the
    -- user can actually see. mfs_get_activity_feed -- the unread feed the panel
    -- renders -- has always excluded dismissed rows; this count did not, so a
    -- dismissed notification kept inflating the badge over a feed that no longer
    -- listed it. Same join, same predicate, so the two now answer the same
    -- question. (Duy, 2026-09-04: a dismissed notification must stop counting.)
    SELECT COUNT(*) AS unread_count
    FROM yp.mfs_changelog c
    INNER JOIN _user_accessible_hubs ah ON c.hub_id = ah.hub_id
    LEFT JOIN mfs_dismissed dm
      ON dm.changelog_id = c.id AND dm.user_id = _user_id
    WHERE c.id > _last_read_id
      AND c.uid != _user_id
      AND dm.changelog_id IS NULL;
    
    DROP TABLE IF EXISTS _user_accessible_hubs;
  END IF;
  
END$

DELIMITER ;