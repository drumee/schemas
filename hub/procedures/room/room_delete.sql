
DELIMITER $

DROP PROCEDURE IF EXISTS `room_delete`$
CREATE PROCEDURE `room_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  DELETE FROM room_attendee WHERE room_id=_id;
  DELETE FROM yp.room_endpoint WHERE room_id=_id;
  DELETE FROM yp.room WHERE id=_id;
  DELETE FROM media WHERE id=_id;
END$
DELIMITER ;

