DELIMITER $
DROP FUNCTION IF EXISTS `duration_days`$
CREATE FUNCTION `duration_days`(
  expiry_time INT(11)
) RETURNS INTEGER DETERMINISTIC
BEGIN 
  DECLARE _res INTEGER;
  DECLARE _ts INT(11);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT  CASE 
    WHEN expiry_time = 0 THEN  NULL
    WHEN (expiry_time - _ts) < 86400  THEN 0
    WHEN (expiry_time - _ts) > 86400  THEN FLOOR((expiry_time - _ts)/86400)
  END INTO _res;
  RETURN _res;
END$
DELIMITER ;
