
DELIMITER $

DROP PROCEDURE IF EXISTS `room_attendees`$
CREATE PROCEDURE `room_attendees`(
  IN _room_id VARCHAR(16)
)
BEGIN
  SELECT DISTINCT
    r.id,
    r.id AS room_id,
    a.id AS user_id, 
    a.device_id, 
    a.socket_id, 
    r.presenter_id, 
    r.ctime, 
    r.hub_id,
    a.id AS avatar_id,
    database() AS hub_db,
    a.role,
    user_permission(a.id, a.room_id) AS permission,
    COALESCE(dr.email, u.email) email, 
    COALESCE(dr.firstname, u.name) firstname, 
    COALESCE(dr.lastname, u.name) lastname, 
    COALESCE(dr.fullname, u.name) fullname,
    r.type,
    s.server AS endpointAddress,
    s.location AS endpointRoute,
    s.server AS use_node,
    s.location AS use_location,
    r.status
  FROM yp.room r  
    INNER JOIN room_attendee a ON a.type = r.type
    INNER JOIN yp.socket s ON a.socket_id = s.id
    LEFT JOIN yp.drumate dr ON dr.id=a.id
    LEFT JOIN yp.dmz_user u ON u.id=a.id
    WHERE a.room_id = _room_id AND s.state='active' 
    GROUP BY a.socket_id;

END$
DELIMITER ;

