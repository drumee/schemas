DELIMITER $

DROP FUNCTION IF EXISTS `read_json_array`$
CREATE FUNCTION `read_json_array`(
  _json json,
  _index int(8) unsigned
)
RETURNS text DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$[", _index, "]"))), '')) INTO _res;
  RETURN _res;
END$

DELIMITER ;