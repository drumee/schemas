DELIMITER $

DROP PROCEDURE IF EXISTS `sys_conf_set`$
CREATE PROCEDURE `sys_conf_set`(
  IN _key VARCHAR(100),
  IN _value JSON
)
BEGIN
  REPLACE INTO sys_conf VALUES(_key, _value);
END$

DELIMITER ;