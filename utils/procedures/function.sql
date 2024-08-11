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

DROP FUNCTION IF EXISTS `get_json_object`$
CREATE FUNCTION `get_json_object`(
  _json json,
  _name text
)
RETURNS text DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$.", _name))) INTO _res;
  RETURN _res;
END$


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

DROP FUNCTION IF EXISTS `get_json_array`$
CREATE FUNCTION `get_json_array`(
  _json json,
  _index int(8) unsigned
)
RETURNS text DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$[", _index, "]"))) INTO _res;
  RETURN _res;
END$

DROP FUNCTION IF EXISTS `domain_name`$
CREATE FUNCTION `domain_name`(
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT conf_value FROM yp.sys_conf WHERE conf_key='domain_name' INTO _res;
  RETURN _res;
END$

DROP FUNCTION IF EXISTS `get`$
CREATE FUNCTION `get`(
  _k VARCHAR(120)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT conf_value FROM yp.sys_conf WHERE conf_key=_k INTO _res;
  RETURN _res;
END$


DROP FUNCTION IF EXISTS `clean_path`$
CREATE FUNCTION `clean_path`(
  _path VARCHAR(1024)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  SELECT REGEXP_REPLACE(_path, '/+', '/') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\<.*\>', '') INTO _r;
  RETURN _r;
END$



DELIMITER ;