DELIMITER $
DROP PROCEDURE IF EXISTS `intl_update_by_id_next`$
CREATE PROCEDURE `intl_update_by_id_next`(
  IN _id INTEGER,
  IN _value TEXT
)
BEGIN

  DECLARE _lng VARCHAR(30) DEFAULT 'ui';
  DECLARE _cat VARCHAR(30) DEFAULT 'ui';
  DECLARE _key VARCHAR(80) DEFAULT '';
  SELECT lng, category, key_code FROM languages 
    WHERE sys_id=_id INTO _lng, _cat, _key;
  IF _lng IS NOT NULL THEN 
    UPDATE languages SET `des`=_value WHERE sys_id=_id;
    SELECT *, sys_id id, 'previous' position FROM languages 
      WHERE key_code < _key AND lng=_lng AND category=_cat LIMIT 1;
    SELECT *, sys_id id, 'current' position FROM languages  WHERE sys_id=_id;
    SELECT *, sys_id id, 'next' position FROM languages 
      WHERE key_code > _key AND lng=_lng AND category=_cat LIMIT 1;
  END IF;
END $
DELIMITER ;
