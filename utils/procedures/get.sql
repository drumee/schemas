DELIMITER $

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

DELIMITER ;