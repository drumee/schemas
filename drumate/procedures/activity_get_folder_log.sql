-- File: schemas/drumate/procedures/activity_get_folder_log.sql
-- Purpose: Get activity log for a SPECIFIC folder
-- Shows only MFS events related to the specified folder

DELIMITER $

DROP PROCEDURE IF EXISTS `activity_get_folder_log`$

CREATE PROCEDURE `activity_get_folder_log`(
  IN _user_id VARCHAR(16),
  IN _nid VARCHAR(16),
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
  
  -- Return MFS activities filtered by node/folder
  -- Events where the node is either source or destination
  -- Or where the parent folder matches (for files inside the folder)
  SELECT 
    c.id,
    c.timestamp,
    c.uid,
    c.event,
    'mfs' AS event_type,
    c.src,
    c.dest,
    IF(c.id > _last_read_id, 0, 1) AS is_read,
    d.firstname,
    d.lastname,
    d.fullname,
    c.hub_id,
    e.db_name AS hub_db_name
  FROM yp.mfs_changelog c
  LEFT JOIN yp.drumate d ON c.uid = d.id
  LEFT JOIN yp.entity e ON c.hub_id = e.id
  WHERE (
    -- File/folder itself is the target
    JSON_VALUE(c.src, '$.nid') = _nid 
    OR JSON_VALUE(c.dest, '$.nid') = _nid
    -- Or file is inside this folder
    OR JSON_VALUE(c.src, '$.parent_id') = _nid
    OR JSON_VALUE(c.dest, '$.parent_id') = _nid
  )
  AND c.uid != _user_id
  ORDER BY c.timestamp DESC
  LIMIT _offset, _range;
  
END$

DELIMITER ;