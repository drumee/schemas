DELIMITER $

DROP PROCEDURE IF EXISTS `custom_table_delete`$
CREATE PROCEDURE `custom_table_delete`(
  IN _name VARCHAR(80)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _count INTEGER;
  SELECT id FROM custom WHERE `name`=_name INTO _id;
  IF _id IS NOT NULL THEN 
    DELETE FROM  custom WHERE `id`=_id;
    SET @s = CONCAT("DROP TABLE `", _id, "`;");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT _name AS name, _id AS id, 'deleted';
  END IF;
END$

DELIMITER ;
