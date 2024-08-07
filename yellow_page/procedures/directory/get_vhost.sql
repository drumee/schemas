DELIMITER $
DROP FUNCTION IF EXISTS `get_vhost`$
CREATE FUNCTION `get_vhost`(
  _ident VARCHAR(80)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  SELECT CONCAT(_ident, '.', main_domain()) INTO _res;
  RETURN _res;
END$

DELIMITER ;
