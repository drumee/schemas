DELIMITER $
DROP PROCEDURE IF EXISTS `token_update`$
CREATE PROCEDURE `token_update`(
 IN _secret      VARCHAR(512),
 IN _metadata JSON 
)
BEGIN
  UPDATE token SET metadata = _metadata WHERE secret = _secret;
END$

DELIMITER ;