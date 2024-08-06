DELIMITER $
DROP PROCEDURE IF EXISTS `plf_search_fonts`$
CREATE PROCEDURE `plf_search_fonts`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  IF _pattern='' OR _pattern is NULL THEN
     SET _pattern = 'a';
  END IF;

  SELECT *,_page as `page`,
  MATCH(`family`, `local1`, `local2`, `url`) against(concat('*', _pattern, '*') IN BOOLEAN MODE) as relevance
  FROM font HAVING relevance > 1 OR family LIKE concat("%", _pattern, "%")
  ORDER BY relevance DESC, family ASC LIMIT _offset, _range;
END$
DELIMITER ;
