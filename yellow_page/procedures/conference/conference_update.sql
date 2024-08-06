
DELIMITER $
DROP PROCEDURE IF EXISTS `conference_update`$
CREATE PROCEDURE `conference_update`(
  IN _room_id VARCHAR(16) CHARACTER SET ascii,
  IN _socket_id VARCHAR(30) CHARACTER SET ascii,
  IN _metadata json 
)
BEGIN
  SELECT metadata FROM conference WHERE room_id = _room_id AND `socket_id` = _socket_id INTO @metadata;
  UPDATE conference SET metadata = JSON_MERGE_PATCH(metadata, @metadata, _metadata) 
    WHERE room_id = _room_id AND socket_id =_socket_id;
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
    coalesce(guest_name, u.firstname, d.firstname) firstname, 
    coalesce(guest_name, u.firstname, d.firstname) username, 
    coalesce(u.lastname, d.lastname, '') lastname,
    s.id socket_id,
    s.server
    FROM yp.conference u 
      INNER JOIN yp.socket s ON u.socket_id=s.id 
      INNER JOIN yp.cookie c ON s.cookie=c.id
      LEFT JOIN yp.drumate d on c.uid=d.id
    WHERE u.room_id = _room_id AND socket_id =_socket_id;

END$


DELIMITER ;