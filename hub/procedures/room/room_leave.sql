
DELIMITER $

DROP PROCEDURE IF EXISTS `room_leave_next`$
CREATE PROCEDURE `room_leave_next`(
  IN _room_id VARCHAR(16),
  IN _socket_id VARCHAR(64)
)
BEGIN
  DECLARE _count INTEGER DEFAULT 0;

  DELETE FROM room_attendee WHERE socket_id=_socket_id AND room_id=_room_id;
  SELECT count(*) FROM media WHERE id=_room_id INTO _count;
  IF _count = 0 THEN 
    CALL permission_revoke(_room_id, '');
  END IF;
  DELETE r FROM yp.room r INNER JOIN yp.entity e  ON r.hub_id=e.id
    WHERE e.db_name = DATABASE() AND presenter_id=_socket_id AND r.id=_room_id;
  SELECT count(*) AS peers_count FROM room_attendee WHERE 
    room_id = _room_id AND device_id IS NOT NULL;
END$

DELIMITER ;
