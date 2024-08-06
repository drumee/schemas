DELIMITER $

DROP PROCEDURE IF EXISTS `get_finger_print`$
CREATE PROCEDURE `get_finger_print`(
  IN _key VARCHAR(255) )
BEGIN
  SELECT fingerprint FROM drumate_view WHERE id=_key OR email=_key OR ident=_key ;
END$
DELIMITER ;