DELIMITER $
DROP PROCEDURE IF EXISTS `plf_icons_list`$
CREATE PROCEDURE `plf_icons_list`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    _page as `page`, 
    `name` as iconName 
  FROM icons ORDER BY `name` ASC LIMIT _offset, _range;

END$
DELIMITER ;
