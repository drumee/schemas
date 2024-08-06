DELIMITER $

DROP PROCEDURE IF EXISTS `get_user_from_socket`$
CREATE PROCEDURE `get_user_from_socket`(
  IN _id VARCHAR(100)
)
BEGIN
  SELECT 
    COALESCE(d.fullname, z.name, c.guest_name) display, 
    COALESCE(d.fullname, z.name, c.guest_name) username, 
    c.uid, 
    s.id socket_id
    -- c.ctime, 
    -- c.id `sid` 
  FROM cookie c 
    INNER JOIN socket s ON s.cookie=c.id 
    LEFT JOIN drumate d ON d.id = c.uid
    LEFT JOIN dmz_user z ON z.id = c.uid
  WHERE s.id = _id
  LIMIT 1;
END$

DELIMITER ;