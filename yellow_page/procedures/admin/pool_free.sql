DELIMITER $

DROP FUNCTION IF EXISTS `pool_free`$
CREATE FUNCTION `pool_free`(
  _type VARCHAR(80)
)
RETURNS VARCHAR(512) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(512);
  select count(id) from yp.entity where area='pool' and type=_type INTO _res;
  RETURN _res;
END$

DELIMITER ;
