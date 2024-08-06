DELIMITER $
DROP FUNCTION IF EXISTS `license`$
CREATE FUNCTION `license`(
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  SELECT JSON_VALUE(conf_value, "$.key")  AS license_key FROM sys_conf WHERE conf_key='license' INTO _r;
  RETURN _r;
END$


DELIMITER ;
-- #####################
