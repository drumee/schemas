


DELIMITER $
DROP PROCEDURE IF EXISTS `organisation_update_dir_visiblity`$
CREATE PROCEDURE `organisation_update_dir_visiblity`(
  _uid VARCHAR(16),
  _id VARCHAR(16),
  _option VARCHAR(15) 
)
BEGIN
  
  UPDATE organisation SET dir_visibility=_option WHERE id = _id; 

  CALL  my_organisation(_uid);
END$

DELIMITER ;