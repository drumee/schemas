DELIMITER $

DROP PROCEDURE IF EXISTS `secret_create`$
CREATE PROCEDURE `secret_create`(
  IN _uid VARCHAR(16),
  IN _secret VARCHAR(64)
)
BEGIN
  DECLARE _code VARCHAR(64);
  SELECT GROUP_CONCAT( ROUND(RAND()*9), ROUND(RAND()*9),ROUND(RAND()*9), ROUND(RAND()*9),ROUND(RAND()*9), ROUND(RAND()*9) ) INTO _code;
  INSERT IGNORE 
    INTO secret(`uid`, `secret`, `code`, `ctime`) 
    VALUE(_uid, _secret, _code, UNIX_TIMESTAMP());
  SELECT *, ctime + 60*10 expiry FROM secret WHERE `secret`=_secret ORDER BY sys_id DESC LIMIT 1;
END$
DELIMITER ;