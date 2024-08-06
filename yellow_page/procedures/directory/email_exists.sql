DELIMITER $

DROP PROCEDURE IF EXISTS `email_exists`$
CREATE PROCEDURE `email_exists`(
  IN _key VARCHAR(128)
)
BEGIN
  SELECT email, id FROM drumate WHERE email=_key;
END$

DROP FUNCTION IF EXISTS `email_exists`$
CREATE FUNCTION `email_exists`(
  _key  varchar(512)
)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
  DECLARE _email VARCHAR(512);
  SELECT email FROM drumate WHERE email=_key INTO _email;
   IF _email IS NOT NULL OR _email != '' THEN
     RETURN TRUE;
   END IF;
  RETURN FALSE;
END$


DELIMITER ;