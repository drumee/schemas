DELIMITER $

DROP PROCEDURE IF EXISTS `get_sys_conf`$
CREATE PROCEDURE `get_sys_conf`(
)
BEGIN
  SELECT conf_key AS `key`, conf_value AS `value` FROM sys_conf;
END $

DROP PROCEDURE IF EXISTS `sysconf`$
CREATE PROCEDURE `sysconf`(
)
BEGIN
  SELECT conf_key AS `key`, conf_value AS `value` FROM sys_conf;
END $

DELIMITER ;
