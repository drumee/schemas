
DELIMITER $

DROP PROCEDURE IF EXISTS `room_invite_next`$
CREATE PROCEDURE `room_invite_next`(
  IN _json json
)
BEGIN
  CALL permission_grant(
    JSON_VALUE(_json, "$.room_id"), 
    JSON_VALUE(_json, "$.user_id"), 
    24, 
    3, 
    'no_traversal', 
    JSON_VALUE(_json, "$.socket_id")
  );
  REPLACE INTO room_attendee (
    id, 
    privilege,
    device_id, 
    socket_id, 
    room_id, 
    `type`,
    ctime, 
    `role`
  )
  VALUES(
    JSON_VALUE(_json, "$.user_id"), 
    7,
    JSON_VALUE(_json, "$.device_id"), 
    JSON_VALUE(_json, "$.socket_id"), 
    JSON_VALUE(_json, "$.room_id"),
    JSON_VALUE(_json, "$.type"),
    UNIX_TIMESTAMP(), 
    JSON_VALUE(_json, "$.role")
  );

END$
DELIMITER ;

