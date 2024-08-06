
DELIMITER $
DROP PROCEDURE IF EXISTS `room_access`$
CREATE PROCEDURE `room_access`(
  IN _socket_id VARCHAR(64),
  IN _user_id VARCHAR(16),
  IN _room_id VARCHAR(16)
)
BEGIN
  DECLARE _privilege TINYINT(2) DEFAULT 0;
  DECLARE _avatar_id VARCHAR(16) DEFAULT NULL;
  DECLARE _screen_id VARCHAR(16) DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16) DEFAULT NULL;
  DECLARE _drumate_db VARCHAR(32) DEFAULT NULL;
  DECLARE _username VARCHAR(128);
  DECLARE _start_time INT(11) UNSIGNED DEFAULT 0;

  SELECT d.fullname, d.id FROM yp.socket s INNER JOIN 
    yp.drumate d ON d.id=s.uid WHERE s.id=_socket_id AND 
    d.id!='ffffffffffffffff' AND `state` != 'idle'
  LIMIT 1 INTO _username, _avatar_id; 
  
  IF( _avatar_id IS NULL) THEN 
    SELECT c.guest_name, c.uid FROM yp.cookie c INNER JOIN 
      yp.socket s ON s.cookie = c.id WHERE s.id=_socket_id AND s.state='active'
    ORDER BY LENGTH(c.id) ASC LIMIT 1 INTO _username, _avatar_id;
  END IF;

  SELECT IFNULL(db_name, 'B_nobody') FROM yp.entity WHERE id=_user_id INTO _drumate_db;
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _hub_id;
  SELECT id FROM yp.room WHERE 
    hub_id=_hub_id AND `type`='screen' LIMIT 1 INTO _screen_id;

  SELECT DISTINCT
    r.id,
    r.id AS room_id,
    a.id AS user_id, 
    a.socket_id, 
    r.presenter_id, 
    r.ctime, 
    r.hub_id,
    _avatar_id AS avatar_id,
    _username AS username,
    _username AS guest_name,
    database() AS hub_db,
    _drumate_db AS db_name,
    a.role,
    _screen_id AS screen_id,
    a.privilege AS permission,
    r.type,
    e.server AS use_node,
    e.location AS use_location,
    e.server AS pushNode,
    e.location AS pushLocation,
    e.server AS endpointAddress,
    e.location AS endpointRoute,
    r.status
  FROM yp.room r  
    INNER JOIN room_attendee a ON a.type = r.type
    INNER JOIN yp.room_endpoint e ON e.room_id = r.id
    WHERE r.id = _room_id AND a.socket_id=_socket_id;

END$

DELIMITER ;

