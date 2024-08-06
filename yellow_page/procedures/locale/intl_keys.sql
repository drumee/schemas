DELIMITER $
DROP PROCEDURE IF EXISTS `intl_keys_next`$
CREATE PROCEDURE `intl_keys_next`(
  IN _key VARCHAR(80),
  IN _cat VARCHAR(80)
)
BEGIN
  IF LENGTH(_key) < 3 THEN
    SET @pattern = CONCAT(TRIM(_key), '%');
  ELSE
    SET @pattern = CONCAT('%', TRIM(_key), '%');
  END IF;

  SELECT DISTINCT(key_code) AS content FROM languages WHERE 
    (key_code LIKE @pattern OR `des`LIKE @pattern) AND category=_cat 
    LIMIT 20;
END $
DELIMITER ;
