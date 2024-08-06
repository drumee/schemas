DELIMITER $
DROP PROCEDURE IF EXISTS `hub_online_guests`$
CREATE PROCEDURE `hub_online_guests`(
  IN _nid VARCHAR(16)
)
BEGIN
  SELECT DISTINCT
    m.id, 
    email, 
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN yp.socket s ON s.uid=p.entity_id
      INNER JOIN room r ON r.socket_id=s.id
      INNER JOIN yp.dmz_user m ON r.user_id=m.id
    WHERE resource_id=_nid AND s.state='active';
END$
DELIMITER ;