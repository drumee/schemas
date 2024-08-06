DELIMITER $
DROP PROCEDURE IF EXISTS `hub_online_members`$
CREATE PROCEDURE `hub_online_members`(
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
      ON p.entity_id=s.uid AND s.uid=d.id  
      WHERE resource_id="*" AND s.state ='active'
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
      INNER JOIN yp.socket s ON p.entity_id = s.uid
      INNER JOIN yp.dmz_user m ON p.entity_id = m.id
      WHERE s.state ='active'
  );

END$
DELIMITER ;