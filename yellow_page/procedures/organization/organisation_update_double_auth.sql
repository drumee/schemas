


DELIMITER $
DROP PROCEDURE IF EXISTS `organisation_update_double_auth`$
CREATE PROCEDURE `organisation_update_double_auth`(
  _uid VARCHAR(16),
  _id VARCHAR(16),
  _option INT(4) 
)
BEGIN
  
  UPDATE organisation SET double_auth=_option WHERE id = _id; 

  CALL  my_organisation(_uid);
END$



DELIMITER ;