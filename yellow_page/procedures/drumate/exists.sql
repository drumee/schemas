DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_exists`$
CREATE PROCEDURE `drumate_exists`(
  IN _id          VARCHAR(500)
)
BEGIN
  SELECT drumate.id, email, domain, firstname, lastname,otp, username ident, username , domain_id,home_dir,
    read_json_object(profile, "mobile")  mobile 
  FROM drumate JOIN entity ON entity.id = drumate.id
  WHERE drumate.id = _id OR email = _id;
END$

DELIMITER ;
