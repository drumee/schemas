DELIMITER $
DROP PROCEDURE IF EXISTS `redirect`$
CREATE PROCEDURE `redirect`(
  IN _fn VARCHAR(250),
  IN _key VARCHAR(250)
)
BEGIN
  DECLARE _db VARCHAR(255);
  SELECT CONCAT('`', db_name, '`') FROM entity 
  WHERE vhost=_key or id=_key or ident=_key INTO _db;
  IF _db != '' OR _db IS NOT NULL THEN
    SET @s1 = CONCAT("CALL ",_db, ".", _fn, "()");

    PREPARE stmt FROM @s1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $

DELIMITER ;
