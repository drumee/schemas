DELIMITER $

DROP PROCEDURE IF EXISTS `session_reset`$
CREATE PROCEDURE `session_reset`(
  IN _cid VARCHAR(128),
  IN _uid VARCHAR(128),
  IN _socket_id VARCHAR(64)
)
BEGIN
  DECLARE _sid VARCHAR(64);
  SELECT cookie FROM socket WHERE id=_socket_id AND cookie=_cid INTO _sid;
  IF(_sid IS NOT NULL) THEN 
    UPDATE socket SET `state`='idle' WHERE id=_socket_id;
    DELETE FROM cookie WHERE id=_sid AND id=_cid;
  END IF;

END$

DELIMITER ;