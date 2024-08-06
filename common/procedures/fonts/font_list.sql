DELIMITER $
DROP PROCEDURE IF EXISTS `font_list`$
CREATE PROCEDURE `font_list`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT * FROM `font` ORDER BY `name` ASC LIMIT _offset, _range;
END $

DELIMITER ;
