DELIMITER $
DROP PROCEDURE IF EXISTS `hub_online_server_members`$
CREATE PROCEDURE `hub_online_server_members`(
  IN _server varchar(256)
)
BEGIN
  (SELECT DISTINCT
    1 isDrumate,
    `uid`, 
    `uid` AS id, 
    firstname, 
    lastname, 
    fullname,      
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN (yp.socket s, yp.drumate d)      
      ON p.entity_id=s.uid AND s.uid=d.id AND s.server = _server 
      WHERE s.state = 'active' AND resource_id="*"
  )
  UNION
  (SELECT DISTINCT
    0 isDrumate,
    s.uid `uid`, 
    m.id, 
    email firstname, 
    email lastname, 
    email fullname, 
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN yp.socket s ON ( p.entity_id = s.uid AND s.server = _server )
      INNER JOIN yp.dmz_user m ON p.entity_id = m.id
      WHERE s.state='active'  
  );

END$
DELIMITER ;

