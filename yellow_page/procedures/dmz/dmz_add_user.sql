DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_add_user`$
CREATE PROCEDURE `dmz_add_user`(
  IN _email      VARCHAR(500),
  IN _name       VARCHAR(500)
)
BEGIN
  DECLARE _id  VARCHAR(16) ; 
  SELECT yp.uniqueId() INTO _id;
  SELECT id FROM dmz_user WHERE email = _email INTO _id; 
  IF _name IS NULL OR _name = '' THEN
    SELECT REPLACE(_email, concat('@',SUBSTRING_INDEX (_email, '@', -1)), "") INTO _name;
  END IF;
  REPLACE INTO dmz_user (id, email, `name`) 
    SELECT  _id, _email, _name;
  SELECT * FROM dmz_user WHERE id = _id;
END$

DELIMITER ;