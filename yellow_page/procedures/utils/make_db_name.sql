DELIMITER $
DROP FUNCTION IF EXISTS `make_db_name`$
CREATE FUNCTION `make_db_name`(

)
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(20);
  SELECT concat(substring(uniqueId(),-1,1), '_', uniqueId()) INTO _res;
  RETURN _res;
END$
DELIMITER ;
