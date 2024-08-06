DELIMITER $
DROP FUNCTION IF EXISTS `get_area_id`$
CREATE FUNCTION `get_area_id`(
  _level VARCHAR(16),
  _owner VARCHAR(16)
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(120);
  SELECT id FROM area WHERE owner_id=_owner and level=_level INTO _res;
  SELECT IF(_res IS NULL, 'private', _res) INTO _res;
  RETURN _res;
END$
DELIMITER ;
