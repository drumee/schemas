DELIMITER $

DROP PROCEDURE IF EXISTS `session_logout`$
CREATE PROCEDURE `session_logout`(
  IN _key VARCHAR(128),
  IN _uid VARCHAR(16)
)
BEGIN
  DELETE FROM cookie  WHERE id=_key AND `uid`=_uid;
  DELETE FROM socket  WHERE cookie=_key AND `uid`=_uid;
  DELETE FROM cookie WHERE UNIX_TIMESTAMP() - mtime > 7*24*60*60;
END$


DROP PROCEDURE IF EXISTS `session_logout_by_admin`$
CREATE PROCEDURE `session_logout_by_admin`(
  IN _uid VARCHAR(16)
 )
BEGIN
  -- UPDATE socket SET `state`='idle' WHERE id=_uid;
  DELETE FROM socket  WHERE `uid`=_uid;
END $

DELIMITER ;