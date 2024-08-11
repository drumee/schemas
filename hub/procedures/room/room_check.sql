
DROP PROCEDURE IF EXISTS `room_check`;
 
-- DELIMITER $

-- ==============================================================
-- 
-- ==============================================================
-- DROP PROCEDURE IF EXISTS `room_check_next`$
-- CREATE PROCEDURE `room_check`(
--   IN _socket_id VARCHAR(64),
--   IN _room_id VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _privilege TINYINT(2) DEFAULT 0;
--   DECLARE _start_time INT(11) UNSIGNED;
--   DECLARE _user_id VARCHAR(16) DEFAULT NULL;
--   DECLARE _avatar_id VARCHAR(16) DEFAULT NULL;
--   DECLARE _screen_id VARCHAR(16) DEFAULT NULL;
--   DECLARE _drumate_db VARCHAR(32) DEFAULT NULL;
--   DECLARE _guest_name VARCHAR(128);
  
--   SELECT permission, s.uid FROM permission p LEFT JOIN yp.socket s 
--     ON s.uid=p.entity_id 
--     WHERE (p.resource_id='*' OR p.resource_id=_room_id) AND s.id=_socket_id AND s.state='active'
--     ORDER BY permission DESC LIMIT 1
--     INTO _privilege, _user_id;

--   -- SELECT IF(guest_name='', NULL, guest_name) FROM yp.cookie c 
--   --   INNER JOIN yp.socket s ON s.cookie=c.id WHERE 
--   --   s.id=_socket_id INTO _guest_name;
    
--   SELECT COALESCE(dr.firstname, guest_name, u.name), c.uid
--     FROM yp.cookie c 
--     INNER JOIN yp.socket s ON s.cookie=c.id 
--     LEFT JOIN yp.drumate dr ON (dr.id=c.uid)
--     LEFT JOIN yp.dmz_user u ON u.id=c.uid
--     WHERE s.id = _socket_id AND s.state='active'
--     ORDER BY LENGTH(c.id) DESC LIMIT 1  
--     INTO _guest_name, _avatar_id;


--   SELECT IFNULL(db_name, 'B_nobody') FROM yp.entity WHERE id=_user_id INTO _drumate_db;
--   SELECT ctime FROM yp.room r r.id=_room_id INTO _start_time;
--   SELECT id FROM yp.room r INNER JOIN yp.entity e  ON r.hub_id=e.id
--     WHERE e.db_name = DATABASE() AND r.type='screen' AND _start_time < ctime INTO _screen_id;

--   SELECT DISTINCT
--     r.id,
--     r.id AS room_id,
--     a.id AS user_id, 
--     a.socket_id, 
--     r.presenter_id, 
--     r.ctime, 
--     _hub_id AS hub_id,
--     _avatar_id AS avatar_id,
--     database() AS hub_db,
--     _drumate_db AS db_name,
--     a.role,
--     _screen_id AS screen_id,
--     IF(socket_id=_socket_id, 1, 0) rank,
--     _privilege AS permission,
--     COALESCE(dr.email, u.email) email, 
--     COALESCE(dr.firstname, _guest_name, u.name) firstname, 
--     COALESCE(dr.lastname, _guest_name, u.name) lastname, 
--     COALESCE(dr.fullname, _guest_name, u.name) fullname,
--     r.type,
--     r.server AS use_node,
--     r.location AS use_location,
--     r.status
--   FROM yp.room r  
--     INNER JOIN room_attendee a 
--     LEFT JOIN yp.drumate dr ON (dr.id=_user_id)
--     LEFT JOIN yp.dmz_user u ON u.id=_user_id
--     WHERE r.id=_room_id ORDER BY rank DESC;

-- END$

-- DELIMITER ;

