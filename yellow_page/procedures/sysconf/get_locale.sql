DELIMITER $

DROP PROCEDURE IF EXISTS `get_locale_next`$
CREATE PROCEDURE `get_locale_next`(
  IN _lng VARCHAR(20),
  IN _cat VARCHAR(40)
)
BEGIN
  SELECT * FROM languages WHERE category=_cat AND lng=_lng;
END $

DELIMITER ;
