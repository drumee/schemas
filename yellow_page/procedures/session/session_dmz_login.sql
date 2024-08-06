DELIMITER $

-- DROP PROCEDURE IF EXISTS `session_dmz_login_next`$
DROP PROCEDURE IF EXISTS `session_dmz_login`$
CREATE PROCEDURE `session_dmz_login`(
  IN _token      VARCHAR(64),
  IN _pw         VARCHAR(128),
  IN _socket_id varchar(64)
)
BEGIN
  DECLARE _drumate_name VARCHAR(120) DEFAULT NULL;
  DECLARE _guest_name VARCHAR(120) DEFAULT NULL;
  SELECT firstname FROM socket s INNER JOIN 
    drumate d ON d.id=s.uid where s.id=_socket_id and d.id!='ffffffffffffffff' LIMIT 1
  INTO _drumate_name; 
  SELECT c.guest_name FROM cookie c INNER JOIN 
    socket s ON s.cookie = c.id WHERE s.id=_socket_id 
  ORDER BY LENGTH(c.id) ASC LIMIT 1 INTO _guest_name;
  SELECT 
    u.id id,
    u.id guest_id,
    u.email,
    COALESCE(_drumate_name, _guest_name) AS guest_name,
    t.id token,
    t.is_sync,
    t.notify_at
    FROM dmz_user u 
    INNER JOIN dmz_token t ON t.guest_id = u.id
    WHERE t.id = _token AND
    (fingerprint=sha2(_pw, 512) OR fingerprint IS NULL)

    UNION 
  SELECT 
    u.id id,
    u.id guest_id,
    u.id email,
    COALESCE(_drumate_name, _guest_name) AS guest_name,
    t.id token,
    t.is_sync,
    t.notify_at
    FROM dmz_media u 
    INNER JOIN dmz_token t ON t.guest_id = u.id
    WHERE t.id = _token AND
    (fingerprint=sha2(_pw, 512) OR fingerprint IS NULL);

END$

DELIMITER ;