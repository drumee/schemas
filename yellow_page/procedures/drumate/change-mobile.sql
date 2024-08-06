DELIMITER $


-- =========================================================
-- Updates phone of a drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_change_mobile`$
CREATE PROCEDURE `drumate_change_mobile`(
  IN _id      VARBINARY(16),
  IN _mobile   VARCHAR(255)
)
BEGIN
  
  UPDATE drumate SET profile = JSON_SET(profile, '$.mobile', _mobile)  WHERE id=_id;
  SELECT id, profile, firstname, lastname, quota, home_dir FROM drumate INNER JOIN entity USING (id) WHERE id = _id;
 
END$

DELIMITER ;
