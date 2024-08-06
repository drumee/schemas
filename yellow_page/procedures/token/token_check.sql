DELIMITER $
DROP PROCEDURE IF EXISTS `token_check`$
CREATE PROCEDURE `token_check`(
  IN _email       VARCHAR(1024),
  IN _secret      VARCHAR(512),
  IN _method     VARCHAR(200)
)
BEGIN
  SELECT *, (UNIX_TIMESTAMP() - ctime) AS age FROM token WHERE 
    secret=secret AND email=_email AND method=_method;
END$

DELIMITER ;