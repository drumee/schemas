DELIMITER $
DROP PROCEDURE IF EXISTS `token_delete`$
CREATE PROCEDURE ``(
  IN _secret      VARCHAR(512)
)
BEGIN
  DELETE FROM token WHERE secret = _secret; 
  DELETE FROM organisation_token WHERE secret = _secret; 
END$

DELIMITER ;