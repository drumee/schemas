DELIMITER $
DROP PROCEDURE IF EXISTS `get_fonts_links`$
CREATE PROCEDURE `get_fonts_links`(
)
BEGIN
  SELECT * FROM `font_link` where status='active';
END $

DELIMITER ;
