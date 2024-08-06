DELIMITER $
DROP PROCEDURE IF EXISTS `plf_search_lang`$
CREATE PROCEDURE `plf_search_lang`(
  IN _arg VARCHAR(128),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT * ,_page as `page`,  IF(lcid=_arg, 100, 0)
    + IF(locale_en=_arg, 100, 0)
    + IF(locale=_arg, 100, 0)
    + IF(code=_arg, 50, 0)
    + IF(locale_en LIKE concat(_arg, "%"), 25 ,0)
    + IF(locale_en LIKE concat("%", _arg, "%"), 13, 0)
    + IF(locale LIKE concat(_arg, "%"), 25,0)
    + IF(locale LIKE concat("%", _arg, "%"), 13, 0)
    + MATCH(locale_en, locale, comment)
      against(_arg IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) AS score
    FROM `language` HAVING score > 25
    ORDER BY score DESC LIMIT _offset, _range;
END $

DELIMITER ;
