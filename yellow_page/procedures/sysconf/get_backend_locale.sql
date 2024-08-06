DELIMITER $

DROP PROCEDURE IF EXISTS `get_sys_conf`$
CREATE PROCEDURE `get_sys_conf`(
)
BEGIN
  SELECT conf_key AS `key`, conf_value AS `value` FROM sys_conf;

END $

DROP PROCEDURE IF EXISTS `get_ui_locale`$
CREATE PROCEDURE `get_ui_locale`(
)
BEGIN
  SELECT * FROM intl WHERE category='ui';
END $

DROP PROCEDURE IF EXISTS `get_backend_locale`$
CREATE PROCEDURE `get_backend_locale`(
)
BEGIN
  SELECT * FROM intl WHERE category='page';
END $

DROP PROCEDURE IF EXISTS `get_locale_next`$
CREATE PROCEDURE `get_locale_next`(
  IN _lng VARCHAR(20),
  IN _cat VARCHAR(40)
)
BEGIN
  SELECT * FROM languages WHERE category=_cat AND lng=_lng;
END $

DELIMITER ;
