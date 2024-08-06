DELIMITER $
DROP FUNCTION IF EXISTS `read_json_object`$
CREATE FUNCTION `read_json_object`(
  _json json,
  _name text
)
RETURNS text DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$.", _name))), '')) INTO _res;
  RETURN _res;
END$

DELIMITER ;