
DELIMITER $

DROP PROCEDURE IF EXISTS `enterprise_update`$
CREATE PROCEDURE `enterprise_update`(
  IN _key VARCHAR(128) CHARACTER SET ascii,
  IN _data JSON
)
BEGIN

  SET @st = "UPDATE enterprise SET location=? WHERE id=? OR bu_id=?";
  PREPARE stmt FROM @st;
  EXECUTE stmt USING _data, _key, _key;
  DEALLOCATE PREPARE stmt;
  
 SELECT id, `location` FROM enterprise WHERE id=_key OR bu_id=_key;
  
END$

DELIMITER ;