DELIMITER $

DROP PROCEDURE IF EXISTS `socket_set_session_offline`$
DROP PROCEDURE IF EXISTS `socket_set_state`$
CREATE PROCEDURE `socket_set_state`(
  IN _id VARCHAR(80) CHARACTER SET ascii,
  IN _state INT(4)
)
BEGIN
  DECLARE _cookie_id VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  SELECT cookie FROM socket WHERE `state`="active" AND id=_id INTO _cookie_id;
  IF _cookie_id IS NOT NULL THEN
    IF _state = 1 THEN
      UPDATE socket SET `state`="active" WHERE cookie=_cookie_id;
    ELSE
      UPDATE socket SET `state`="idle" WHERE cookie=_cookie_id;
      DELETE FROM cookie WHERE id=_cookie_id;
    END IF;
  END IF;
END$

DELIMITER ;
