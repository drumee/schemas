DELIMITER $
DROP FUNCTION IF EXISTS `main_domain`$
CREATE FUNCTION `main_domain`(
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT conf_value FROM yp.sys_conf WHERE conf_key='domain_name' INTO _res;
  RETURN _res;
END$
DELIMITER ;