


DELIMITER $
DROP PROCEDURE IF EXISTS `organisation_update_password_level`$
CREATE PROCEDURE `organisation_update_password_level`(
  _uid VARCHAR(16),
  _id VARCHAR(16),
  _option INT(4) 
)
BEGIN
  
  UPDATE organisation SET password_level=_option WHERE id = _id; 

  CALL  my_organisation(_uid);
END$
DELIMITER ;