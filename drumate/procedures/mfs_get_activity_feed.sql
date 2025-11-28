-- File: schemas/drumate/procedures/mfs_get_activity_feed.sql
-- Purpose: Get activity feed with read/unread status

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_activity_feed`$

CREATE PROCEDURE `mfs_get_activity_feed`(
  IN _user_id VARCHAR(16),
  IN _limit INT,
  IN _offset INT
)
BEGIN
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;
  
  SELECT IFNULL(last_read_id, 0) INTO _last_read_id
  FROM mfs_ack
  WHERE user_id = _user_id;
  
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
  LEFT JOIN yp.drumate d ON c.uid = d.id
  LEFT JOIN yp.entity e ON c.hub_id = e.id
  WHERE c.uid != _user_id  -- Exclude own actions
  ORDER BY c.id DESC
  LIMIT _limit OFFSET _offset;
  
END$

DELIMITER ;