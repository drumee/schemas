-- =========================================================
-- get_visitor
-- =========================================================
DELIMITER $

DROP FUNCTION IF EXISTS `get_remit`$
CREATE FUNCTION `get_remit`(
  _key  varchar(512)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  SELECT remit FROM drumate WHERE id=_key INTO _res ;
  RETURN _res;
END$

DELIMITER ;