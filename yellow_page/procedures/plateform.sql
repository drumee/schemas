DELIMITER $

-- =========================================================
--
-- PLATEFORM STUFF
--
-- =========================================================
-- =========================================================
-- plf_icons_list
-- List icons available on the plateform
-- =========================================================

DROP PROCEDURE IF EXISTS `plf_icons_list`$
CREATE PROCEDURE `plf_icons_list`(
  -- IN _lang VARBINARY(16),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT _page as `page`, `name` as iconName from icons ORDER BY `name` ASC LIMIT _offset, _range;

END$

-- =========================================================
-- plf_icons_search
-- List icons available on the plateform
-- =========================================================

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

-- =========================================================
-- plf_fonts_list
-- List fonts available on the plateform
-- =========================================================

DROP PROCEDURE IF EXISTS `plf_fonts_list`$
CREATE PROCEDURE `plf_fonts_list`()
BEGIN
  SELECT family, GROUP_CONCAT(DISTINCT NAME ORDER BY NAME DESC SEPARATOR ':') AS `name` FROM font GROUP BY family;
END$


-- =========================================================
-- get_intl_msg
-- Get internationalized messages
-- =========================================================

DROP PROCEDURE IF EXISTS `plf_list_models`$
CREATE PROCEDURE `plf_list_models`(
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  SELECT * , _page as `page` FROM  2_4b40d5b94b40d5bd.block where status='online' ORDER BY mtime DESC LIMIT _offset, _range;
END$


-- =========================================================
-- get_intl_msg
-- Get internationalized messages
-- =========================================================

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


-- =========================================================
-- find rows in lexicon
-- =========================================================
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

-- #####################
