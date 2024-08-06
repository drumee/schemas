DELIMITER $

-- =========================================================
-- Updates email of a drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_change_email`$
CREATE PROCEDURE `drumate_change_email`(
  IN _id      VARBINARY(16),
  IN _email   VARCHAR(255)
)
BEGIN
  
  UPDATE drumate SET profile = JSON_SET(profile, '$.email', _email)  WHERE id=_id;
  SELECT id, profile, firstname, lastname, quota, home_dir FROM drumate INNER JOIN entity USING (id) WHERE id = _id;
 
END$

DELIMITER ;
