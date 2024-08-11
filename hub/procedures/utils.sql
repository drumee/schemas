DELIMITER $

-- =========================================================
-- statistics_add
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_clone_content`$
CREATE PROCEDURE `hub_clone_content`(
  IN _src_id VARCHAR(160)
)
BEGIN
  DECLARE _src_home_id VARCHAR(16);
  DECLARE _src_db VARCHAR(50);
  DECLARE _src_home_dir VARCHAR(120);
  DECLARE _src_name VARCHAR(120);
  DECLARE _dest_home_dir VARCHAR(120);
  DECLARE _dest_home_id VARCHAR(50);
  DECLARE _dest_id VARCHAR(50);

  SELECT home_layout, db_name, home_dir FROM yp.entity WHERE 
    id=_src_id INTO _src_home_id, _src_db, _src_home_dir;

  SELECT id, home_dir FROM yp.entity  WHERE db_name = database() INTO _dest_id, _dest_home_dir;

  SELECT name FROM yp.hub WHERE id = _src_id INTO _src_name;
    
  IF _src_home_id IS NOT NULL THEN
    DELETE FROM media;
    SET @s = CONCAT("INSERT INTO media SELECT * FROM `", _src_db, "`.media");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `block`;
    SET @s = CONCAT("INSERT INTO block SELECT * FROM `", _src_db, "`.block");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `block_history`;
    SET @s = CONCAT("INSERT INTO block_history SELECT * FROM `", _src_db, "`.block_history");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `font_face`;
    SET @s = CONCAT("INSERT INTO font_face SELECT * FROM `", _src_db, "`.font_face");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `font`;
    SET @s = CONCAT("INSERT INTO font SELECT * FROM `", _src_db, "`.font");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `font_link`;
    SET @s = CONCAT("INSERT INTO font_link SELECT * FROM `", _src_db, "`.font_link");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `style`;
    SET @s = CONCAT("INSERT INTO style SELECT * FROM `", _src_db, "`.style");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    CALL yp.hub_update_name(_dest_id, CONCAT(_src_name, " (copy)"));
    
    SELECT 
      _src_home_dir AS src_home_dir, 
      _src_home_id AS src_home_id, 
      _dest_home_dir AS dest_home_dir, 
      _dest_home_id as dest_home_id;
  END IF;
END$


DELIMITER ;