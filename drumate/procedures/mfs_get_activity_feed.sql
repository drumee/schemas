-- File: schemas/drumate/procedures/mfs_get_activity_feed.sql
-- Purpose: Get activity feed with read/unread status

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_activity_feed`$

CREATE PROCEDURE `mfs_get_activity_feed`(
  IN _user_id VARCHAR(16),
  IN _page INT
)
BEGIN
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;
  DECLARE _offset BIGINT;
  DECLARE _range BIGINT;

  CALL pageToLimits(_page, _offset, _range);
  
  SELECT IFNULL(last_read_id, 0) INTO _last_read_id
  FROM mfs_ack
  WHERE user_id = _user_id;

  -- Create temp table of accessible hubs
  DROP TABLE IF EXISTS _user_accessible_hubs;
  CREATE TEMPORARY TABLE _user_accessible_hubs (
    hub_id VARCHAR(16) CHARACTER SET ascii PRIMARY KEY
  );

  -- Insert hubs user owns
  INSERT INTO _user_accessible_hubs (hub_id)
  SELECT id FROM yp.hub WHERE owner_id = _user_id;
  
  -- Insert hubs user is a member of (with valid permission)
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  SELECT entity_id 
  FROM permission 
  WHERE resource_id = _user_id 
    AND expiry_time > UNIX_TIMESTAMP();
  
  -- Insert user's own personal space
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  VALUES (_user_id);
  
  SELECT 
    c.id,
    c.timestamp,
    c.uid,
    c.hub_id,
    c.event,
    c.src,
    c.dest,
    IF(c.id > _last_read_id, 0, 1) AS is_read,
    d.firstname,
    d.lastname,
    d.fullname,
    e.db_name AS hub_db_name
  FROM yp.mfs_changelog c
  INNER JOIN _user_accessible_hubs ah ON c.hub_id = ah.hub_id
  LEFT JOIN yp.drumate d ON c.uid = d.id
  LEFT JOIN yp.entity e ON c.hub_id = e.id
  WHERE c.uid != _user_id  -- Exclude own actions
  ORDER BY c.id DESC
  LIMIT _offset, _range;
  
  DROP TABLE IF EXISTS _user_accessible_hubs;
  
END$

DELIMITER ;