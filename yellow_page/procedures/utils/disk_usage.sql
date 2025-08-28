DELIMITER $
-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `disk_usage`$
DROP PROCEDURE IF EXISTS `disk_usage`$
CREATE PROCEDURE `disk_usage`(
  IN _uid VARCHAR(16) 
)
BEGIN 
  DECLARE _personal BIGINT DEFAULT 0;
  DECLARE _trash BIGINT DEFAULT 0;
  DECLARE _finished BOOLEAN DEFAULT 0;
  DECLARE _db_name VARCHAR(60);

  DECLARE dbcursor CURSOR FOR SELECT e.db_name FROM yp.entity e INNER JOIN yp.hub h USING(id)
    WHERE owner_id=_uid;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

  SET @hub_usage = 0;
  SET @hub_trash = 0;
  SET @personal_usage = 0;
  SET @personal_trash = 0;
  OPEN dbcursor;
    STARTLOOP: LOOP
      FETCH dbcursor INTO _db_name;
      IF _finished = 1 THEN 
        LEAVE STARTLOOP;
      END IF;  
      SET @s=CONCAT(
        "SELECT @hub_usage + IFNULL(sum(filesize), 0) FROM ", _db_name, ".media INTO @hub_usage"
      );
      IF @s IS NOT NULL THEN 
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
      SET @s=CONCAT(
        "SELECT @hub_trash + IFNULL(sum(filesize), 0) FROM ", _db_name, ".trash_media INTO @hub_trash"
      );
      IF @s IS NOT NULL THEN 
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
    END LOOP STARTLOOP;
  CLOSE dbcursor;

  SELECT db_name FROM entity WHERE id=_uid INTO _db_name;
  SET @s=CONCAT("SELECT @personal_usage + IFNULL(sum(filesize), 0) FROM ", _db_name, ".media INTO @personal_usage");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SELECT _db_name;
  SET @s=CONCAT("SELECT @personal_trash + IFNULL(sum(filesize), 0) FROM ", _db_name, ".trash_media INTO @personal_trash");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SELECT 
    @hub_usage hub_usage,
    @hub_trash hub_trash,
    @personal_usage personal_usage,
    @personal_trash personal_trash,
    CAST((@hub_usage + @hub_trash) AS INTEGER) total_hub,
    CAST((@personal_usage + @personal_trash) AS INTEGER) total_personal,
    CAST((@hub_usage + @hub_trash + @personal_usage + @personal_trash) AS INTEGER) total_usage;

END$

DELIMITER ;


