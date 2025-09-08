DELIMITER $

DROP PROCEDURE IF EXISTS `cookie_retrieve_user`$
CREATE PROCEDURE `cookie_retrieve_user`(
  IN _key VARCHAR(512) CHARACTER SET ascii
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  SELECT `uid` FROM cookie WHERE id=_key LIMIT 1 INTO _uid;
  CALL get_user(_uid);
END$


DELIMITER ;