DELIMITER $

DROP FUNCTION IF EXISTS `domain_name`$
CREATE FUNCTION `domain_name`(
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT conf_value FROM yp.sys_conf WHERE conf_key='domain_name' INTO _res;
  RETURN _res;
END$

DELIMITER ;