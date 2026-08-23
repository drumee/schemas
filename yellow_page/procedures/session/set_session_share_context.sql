DELIMITER $

DROP PROCEDURE IF EXISTS `set_session_share_context`$
CREATE PROCEDURE `set_session_share_context`(
  IN _args JSON
)
BEGIN
  DECLARE _sid VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _socket_id VARCHAR(32) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _priv_ceiling TINYINT UNSIGNED DEFAULT NULL;
  DECLARE _existing_sid VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;

  SELECT JSON_VALUE(_args, "$.sid") INTO _sid;
  SELECT JSON_VALUE(_args, "$.uid") INTO _uid;
  SELECT JSON_VALUE(_args, "$.socket_id") INTO _socket_id;
  SELECT CAST(JSON_VALUE(_args, "$.priv_ceiling") AS UNSIGNED)
    INTO _priv_ceiling;

  IF _sid IS NULL OR _sid = '' OR _uid IS NULL OR _uid = '' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SESSION_SHARE_CONTEXT_INVALID';
  END IF;

  SELECT c.id
    INTO _existing_sid
    FROM cookie c
    WHERE c.id = _sid
    LIMIT 1
    FOR UPDATE;
  IF _existing_sid IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SESSION_SHARE_COOKIE_NOT_FOUND';
  END IF;

  UPDATE cookie
    SET mtime = UNIX_TIMESTAMP(),
        guest_name = NULL,
        `uid` = _uid,
        priv_ceiling = _priv_ceiling,
        ceiling_uid = _uid
    WHERE id = _sid;

  IF _socket_id IS NOT NULL THEN
    UPDATE socket s
      INNER JOIN cookie c ON c.id = s.cookie
      SET s.uid = c.uid
      WHERE s.id = _socket_id AND c.id = _sid;
  END IF;
END$

DELIMITER ;
