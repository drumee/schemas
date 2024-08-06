DELIMITER $

DROP PROCEDURE IF EXISTS `intl_get_next`$
CREATE PROCEDURE `intl_get_next`(
  IN _key VARCHAR(80),
  IN _cat VARCHAR(80)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  SELECT *, lng AS `name`, `des` AS `value`, sys_id AS id
    FROM languages WHERE key_code=_key AND category=_cat;
END $
DELIMITER ;
