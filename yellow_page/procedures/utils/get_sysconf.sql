DELIMITER $
DROP FUNCTION IF EXISTS `get_sysconf`$
CREATE FUNCTION `get_sysconf`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT conf_value FROM yp.sys_conf WHERE conf_key=_key INTO _res;
  RETURN _res;
END$
DELIMITER ;