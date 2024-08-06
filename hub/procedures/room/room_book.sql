
DELIMITER $

DROP PROCEDURE IF EXISTS `room_book`$
CREATE PROCEDURE `room_book`(
  IN _user_id VARCHAR(32),
  IN _room_id VARCHAR(32),  
  IN _type VARCHAR(32)
)
BEGIN
  DECLARE _tmp_socket VARCHAR(128);

  INSERT IGNORE INTO room (
    id, 
    user_id, 
    socket_id, 
    ctime, 
    `type`,
    `role`,
    `status`
  )
  VALUES(
    _room_id, 
    _user_id, 
    '*', 
    UNIX_TIMESTAMP(), 
    _type, 
    'presenter',
    'booked'
  );


  SELECT *
    FROM room r  
    WHERE socket_id='*' AND r.type=_type AND r.id=_room_id;
  
END$
DELIMITER ;

