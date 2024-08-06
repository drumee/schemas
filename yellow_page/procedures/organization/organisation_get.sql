


DELIMITER $
DROP PROCEDURE IF EXISTS `organisation_get`$
CREATE PROCEDURE `organisation_get`(
   IN _key VARCHAR(1000)
)
BEGIN
  SELECT *, link `url` FROM organisation WHERE id =_key  
    OR  domain_id = _key  OR link = _key OR name = _key;
END$
DELIMITER ;