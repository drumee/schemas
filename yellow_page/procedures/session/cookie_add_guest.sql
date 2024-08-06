DELIMITER $

DROP PROCEDURE IF EXISTS `cookie_add_guest`$
CREATE PROCEDURE `cookie_add_guest`(
  IN _sid  VARCHAR(128), 
  IN _uid  VARCHAR(16), 
  IN _ua   VARCHAR(255)
)
BEGIN
  DECLARE _guest_name VARCHAR(264);
  IF _sid IS NOT NULL THEN
    REPLACE INTO cookie (`id`,`uid`,`ctime`,`mtime`,`ua`, `status`)
    VALUES(_sid, _uid, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), _ua, 'guest');
    SELECT guest_name FROM cookie WHERE id = _sid INTO _guest_name;
    IF _guest_name IS NOT NULL THEN 
      UPDATE dmz_user SET `name` = _guest_name WHERE id = _uid;
    END IF;
  END IF;

END$

DELIMITER ;