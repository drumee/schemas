DELIMITER $
DROP PROCEDURE IF EXISTS `drumate_get`$
CREATE PROCEDURE `drumate_get`(
  IN _key  VARCHAR(128) CHARACTER SET ascii 
)
BEGIN
  SELECT id, 
    username, 
    `profile`, 
    firstname, 
    lastname, 
    quota, 
    home_dir, 
    JSON_VALUE(profile, '$.lang' ) lang,
    fullname,
    email FROM drumate INNER JOIN entity USING (id) 
    WHERE id = _key OR email = _key;
END$


DELIMITER ;