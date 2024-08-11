
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_get_token`$
CREATE PROCEDURE `licence_get_token`(
 IN _key VARCHAR(1000),
 IN _secret VARCHAR(1000)
)
BEGIN
  SELECT * FROM token WHERE 
    licence_key =_key AND `secret` = _secret 
    AND ctime + 60*60*24 > UNIX_TIMESTAMP();
END$

DELIMITER ;