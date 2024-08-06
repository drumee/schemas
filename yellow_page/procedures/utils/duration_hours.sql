DELIMITER $

DROP FUNCTION IF EXISTS `duration_hours`$
CREATE FUNCTION `duration_hours`(
  expiry_time INT(11)
) RETURNS INTEGER DETERMINISTIC
BEGIN 
  DECLARE _res INTEGER;
  DECLARE _ts INT(11);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT  CASE 
    WHEN expiry_time = 0 THEN  NULL
    WHEN 
    (expiry_time - _ts) > 0  THEN CEIL(MOD((expiry_time - _ts),86400)/3600)  
    WHEN (expiry_time - _ts) > 0  THEN 0
  END INTO _res;
  RETURN _res;
END$

DELIMITER ;
