
DELIMITER $



-- =========================================================
-- conference_attendees
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_attendees`$
CREATE PROCEDURE `conference_attendees`(
  IN _id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
   
  SELECT u.id, metadata, s.id socket_id, coalesce(guest_name, firstname) username, attendee_id
    FROM conference u 
    INNER JOIN socket s ON u.uid=s.id 
    INNER JOIN cookie c ON s.cookie=c.id
    LEFT JOIN drumate d on c.uid=d.id
  WHERE u.id =_id AND s.state='active'; 

END$


DELIMITER ;