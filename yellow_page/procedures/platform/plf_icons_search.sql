DELIMITER $
DROP PROCEDURE IF EXISTS `plf_icons_search`$
CREATE PROCEDURE `plf_icons_search`(
  IN _str VARBINARY(16),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT _page as `page`,`name` as iconName  from icons WHERE `name` LIKE concat("%", _str, "%") 
  ORDER BY `name` ASC LIMIT _offset, _range;

END$
DELIMITER ;
