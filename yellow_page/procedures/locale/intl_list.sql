DELIMITER $
DROP PROCEDURE IF EXISTS `intl_list_next`$
CREATE PROCEDURE `intl_list_next`(
  IN _cat VARCHAR(80),
  IN _page TINYINT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  SET @rows_per_page=100;
  CALL pageToLimits(_page, _offset, _range);
  SELECT _page as `page`, sys_id as id, key_code, lng, `des` 
    FROM languages WHERE category=_cat
  ORDER BY key_code ASC LIMIT _offset, _range;
END $
DELIMITER ;
