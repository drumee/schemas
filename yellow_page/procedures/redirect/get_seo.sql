DELIMITER $

DROP PROCEDURE IF EXISTS `get_seo`$
CREATE PROCEDURE `get_seo`(
  IN _key VARCHAR(250),
  IN _hashtag VARCHAR(128),
  IN _lang VARCHAR(128)
)
BEGIN
  DECLARE _db VARCHAR(255);
  DECLARE _dn VARCHAR(255);

  SELECT CONCAT('`', db_name, '`') FROM entity 
    LEFT JOIN vhost USING(id) WHERE fqdn=_key INTO _db;
  IF _db != '' OR _db IS NOT NULL THEN
    SET @s1 = CONCAT("CALL ",_db, ".seo_get(", quote(_hashtag), ",", quote(_lang), ")");

    PREPARE stmt FROM @s1;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $

DELIMITER ;
