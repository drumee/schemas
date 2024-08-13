
DELIMITER $



-- =========================================================
-- conference_attendee
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_attendee`$
CREATE PROCEDURE `conference_attendee`(
  IN _id VARCHAR(16) CHARACTER SET ascii)
BEGIN
  SELECT 
    u.room_id,
    hub_id,
    participant_id,
    coalesce(u.uid, c.uid, 'default') `uid`,
    audio, 
    video, 
    screen, 
    area,
    permission,
    `role`, 
    IFNULL(CASE 
      WHEN u.type = 'connect' THEN JSON_VALUE(JSON_VALUE(profile, "$.quota"), "$.contact_call")
      WHEN u.type = 'meeting' AND area = 'private' THEN JSON_VALUE(JSON_VALUE(profile, "$.quota"), "$.team_call")
      WHEN u.type = 'meeting' AND area = 'dmz' THEN JSON_VALUE(JSON_VALUE(profile, "$.quota"), "$.meeting_call")
      ELSE 0
    END, 0) quota,
    coalesce(guest_name, u.firstname, d.firstname) firstname, 
    coalesce(guest_name, u.firstname, d.firstname) username, 
    coalesce(u.lastname, d.lastname, '') lastname,
    s.id socket_id,
    s.server
    FROM yp.conference u 
      INNER JOIN yp.socket s ON u.socket_id=s.id 
      INNER JOIN yp.cookie c ON s.cookie=c.id
      LEFT JOIN yp.drumate d on c.uid=d.id
    WHERE u.participant_id =_id AND s.state='active' AND u.participant_id IS NOT NULL;

END$


DELIMITER ;