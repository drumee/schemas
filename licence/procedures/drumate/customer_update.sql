
DELIMITER $

DROP PROCEDURE IF EXISTS `customer_update`$
CREATE PROCEDURE `customer_update`(
  IN _key VARCHAR(128) CHARACTER SET ascii,
  IN _data JSON
)
BEGIN

  SET @st = "UPDATE customer SET location=? WHERE id=?";
  PREPARE stmt FROM @st;
  EXECUTE stmt USING _data, _key;
  DEALLOCATE PREPARE stmt;
  SELECT id, `location` FROM customer WHERE id=_key;
  
END$

DELIMITER ;