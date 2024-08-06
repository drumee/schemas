DELIMITER $

DROP PROCEDURE IF EXISTS `cookie_bind_guest`$
CREATE PROCEDURE `cookie_bind_guest`(
  IN _sid  VARCHAR(128), 
  IN _name   VARCHAR(255)
)
BEGIN

  UPDATE cookie SET `guest_name`=_name WHERE id=_sid;

END$

DELIMITER ;