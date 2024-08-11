
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_new_token`$
CREATE PROCEDURE `licence_new_token`(
 IN _key VARCHAR(1000),
 IN _secret VARCHAR(1000)
)
BEGIN
  REPLACE 
    INTO token(`licence_key`, `secret`, `ctime`) 
    VALUE(_key, _secret, UNIX_TIMESTAMP());
  DELETE FROM token WHERE ctime + 60*60*24 > UNIX_TIMESTAMP();
  SELECT * FROM token WHERE `secret`=_secret;
END$

DELIMITER ;