DELIMITER $
DROP PROCEDURE IF EXISTS `get_laguages`$
CREATE PROCEDURE `get_laguages`(
  IN _name         VARCHAR(200),
  IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    _page as `page`, 
    code, lcid, 
    locale_en, 
    locale, 
    flag_image 
  FROM yp.language WHERE `state` = 'active'
    AND code NOT IN 
      (SELECT locale FROM language WHERE state = 'active' OR state = 'replaced')
    AND locale_en LIKE CONCAT(TRIM(IFNULL(_name, '')), '%')
    ORDER BY locale_en ASC LIMIT _offset, _range;
END$

DELIMITER ;
