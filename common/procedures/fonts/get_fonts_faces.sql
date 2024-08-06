DELIMITER $
DROP PROCEDURE IF EXISTS `get_fonts_faces`$
CREATE PROCEDURE `get_fonts_faces`(
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(40);

  SELECT conf_value FROM yp.sys_conf 
    WHERE conf_key='entry_host' INTO _hub_id;

  SELECT db_name FROM yp.entity e 
    INNER JOIN yp.vhost v ON e.id=v.id WHERE e.id=_hub_id OR v.fqdn=_hub_id INTO _hub_db;

  IF _hub_db IS NOT NULL THEN
    SET @sql = CONCAT("  SELECT * FROM ", _hub_db, ".font_face" );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
  END IF;
END $

DELIMITER ;
