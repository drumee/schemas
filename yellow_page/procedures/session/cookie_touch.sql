DELIMITER $

-- DROP PROCEDURE IF EXISTS `cookie_touch_next`$
DROP PROCEDURE IF EXISTS `cookie_touch`$
CREATE PROCEDURE `cookie_touch`(
  IN _args JSON
)
BEGIN
  DECLARE _sid VARCHAR(256) CHARACTER SET ascii;
  DECLARE _guest_name VARCHAR(256);
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _socket_id VARCHAR(32) CHARACTER SET ascii;
  SELECT JSON_VALUE(_args, "$.sid") INTO _sid;
  SELECT JSON_VALUE(_args, "$.uid") INTO _uid;
  SELECT JSON_VALUE(_args, "$.guest_name") INTO _guest_name;
  SELECT JSON_VALUE(_args, "$.socket_id") INTO _socket_id;

  UPDATE cookie SET mtime=unix_timestamp(), guest_name=_guest_name, `uid`=_uid WHERE id=_sid;
  IF _socket_id IS NOT NULL THEN
    UPDATE socket s INNER JOIN cookie c ON c.id=s.cookie 
    SET s.uid=c.uid WHERE s.id=_socket_id;
  END IF;
END$

DELIMITER ;