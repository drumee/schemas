DELIMITER $
DROP FUNCTION IF EXISTS `chk_fingerprint`$
CREATE FUNCTION `chk_fingerprint`(
  _pw VARCHAR(16) ,
  _fingerprint VARCHAR(5000) 
)
RETURNS INTEGER DETERMINISTIC
BEGIN
  DECLARE _res INTEGER DEFAULT 0;
  SELECT 
    IF( sha2(_pw, 512)  = _fingerprint , 1, 0) INTO _res;
     RETURN _res;
END$
DELIMITER ;