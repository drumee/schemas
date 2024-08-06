DELIMITER $

DROP PROCEDURE IF EXISTS `set_homepage`$
CREATE PROCEDURE `set_homepage`(
   IN _key VARBINARY(80),
   IN _homepage VARBINARY(80)
)
BEGIN
  DECLARE _id VARBINARY(16);
  UPDATE entity SET homepage = _homepage  WHERE id=_key;

END$


DELIMITER ;
