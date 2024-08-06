DELIMITER $

-- =========================================================
-- Updates email of a drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_change_otp`$
CREATE PROCEDURE `drumate_change_otp`(
  IN _key   VARCHAR(255),
  IN _value BOOLEAN 
)
BEGIN
  
  UPDATE drumate SET profile = JSON_SET(profile, "$.otp", _value)  
    WHERE id=_key OR email=_key;
  SELECT id, JSON_VALUE(profile, "$.otp") otp, firstname, lastname, home_dir 
    FROM drumate INNER JOIN entity USING (id) 
    WHERE id=_key OR email=_key;
 
END$

DELIMITER ;
