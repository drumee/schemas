-- File: schemas/drumate/procedures/activity_get_log.sql
-- Purpose: Get unified activity log (contacts + MFS) with pagination
-- Priority: ALL contact events first, then ALL MFS events

DELIMITER $

DROP PROCEDURE IF EXISTS `activity_get_log`$

CREATE PROCEDURE `activity_get_log`(
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
  
  DROP TABLE IF EXISTS _user_accessible_hubs;
  CREATE TEMPORARY TABLE _user_accessible_hubs (
    hub_id VARCHAR(16) CHARACTER SET ascii PRIMARY KEY
  );
  
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
  
  -- `permission` is the per-user drumate-DB table, NOT yp.permission, which
  -- does not exist. The deployed copy has always read `permission`; this file
  -- had drifted and applying it as-is would have broken the procedure.
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  SELECT entity_id 
  FROM permission 
  WHERE resource_id = _user_id 
    AND expiry_time > UNIX_TIMESTAMP();
  
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  VALUES (_user_id);
  
  DROP TABLE IF EXISTS _unified_activity;
  CREATE TEMPORARY TABLE _unified_activity (
    id INT(11) UNSIGNED,
    timestamp INT(11) UNSIGNED,
    uid VARCHAR(16) CHARACTER SET ascii,
    event VARCHAR(100),
    event_type VARCHAR(20),
    priority INT,
    src JSON,
    dest JSON,
    data JSON,
    is_read TINYINT,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    fullname VARCHAR(200),
    hub_id VARCHAR(16) CHARACTER SET ascii,
    hub_db_name VARCHAR(255),
    KEY idx_priority_time (priority, timestamp)
  );
  
  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name
  )
  SELECT 
    c.id,
    c.timestamp,
    c.uid,
    c.event,
    'contact' AS event_type,
    1 AS priority,
    JSON_OBJECT(
      'uid', c.uid,
      'email', d1.email,
      'fullname', d1.fullname
    ) AS src,
    JSON_OBJECT(
      'uid', c.target_uid,
      'email', d2.email,
      'fullname', d2.fullname
    ) AS dest,
    c.data,
    IF(c.id > _last_read_id, 0, 1) AS is_read,
    d1.firstname,
    d1.lastname,
    d1.fullname,
    NULL AS hub_id,
    NULL AS hub_db_name
  FROM yp.contact_activity c
  LEFT JOIN yp.drumate d1 ON c.uid = d1.id
  LEFT JOIN yp.drumate d2 ON c.target_uid = d2.id
  WHERE (c.uid = _user_id OR c.target_uid = _user_id)
    AND c.uid != _user_id
    AND c.dismissed_at IS NULL;
  
  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name
  )
  SELECT 
    m.id,
    m.timestamp,
    m.uid,
    m.event,
    'mfs' AS event_type,
    2 AS priority,
    m.src,
    m.dest,
    NULL AS data,
    0 AS is_read,
    d.firstname,
    d.lastname,
    d.fullname,
    m.hub_id,
    e.db_name AS hub_db_name
  FROM yp.mfs_changelog m
  INNER JOIN _user_accessible_hubs ah ON m.hub_id = ah.hub_id
  LEFT JOIN yp.drumate d ON m.uid = d.id
  LEFT JOIN yp.entity e ON m.hub_id = e.id
  -- Honor activity.dismiss writes — without this join every dismissed
  -- row keeps surfacing on the next get_feed because the dismissal
  -- only lives in drumate.mfs_dismissed (matches mfs_get_activity_feed).
  LEFT JOIN mfs_dismissed dm
    ON dm.changelog_id = m.id AND dm.user_id = _user_id
  WHERE m.uid != _user_id
    AND m.id > _last_read_id
    AND dm.changelog_id IS NULL;
  
  SELECT 
    id,
    timestamp,
    uid,
    event,
    event_type,
    src,
    dest,
    data,
    is_read,
    firstname,
    lastname,
    fullname,
    hub_id,
    hub_db_name
  FROM _unified_activity
  ORDER BY 
    priority ASC,
    timestamp DESC
  LIMIT _offset, _range;
  
  DROP TABLE IF EXISTS _user_accessible_hubs;
  DROP TABLE IF EXISTS _unified_activity;
  
END$

DELIMITER ;