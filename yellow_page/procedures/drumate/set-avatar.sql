DELIMITER $


-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `drumate_set_avatar`$
CREATE PROCEDURE `drumate_set_avatar`(
  IN _key VARCHAR(255),
  IN _value VARCHAR(255)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _old_avatar VARCHAR(20);
  DECLARE _db_name VARCHAR(80);

  SELECT id, db_name FROM entity WHERE ident=_key OR id=_key INTO _id, _db_name;
  SELECT TRIM('"' FROM JSON_EXTRACT(`profile`,'$.avatar')) FROM drumate WHERE id=_id INTO _old_avatar;
  UPDATE drumate SET `profile`=JSON_SET(`profile`,'$.avatar', _value) where id=_id;

  IF _old_avatar IS NOT NULL OR _old_avatar != '' THEN
    SET @s = CONCAT("DELETE FROM `", _db_name, "`.permission WHERE ", 
      "resource_id = ", QUOTE(_old_avatar), " AND entity_id='ffffffffffffffff'");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  SET @s = CONCAT('CALL `',_db_name , "`.permission_grant(?,'*',0, 1, 'system', '')");
  -- SELECT @s ;
  PREPARE stmt FROM @s;
  EXECUTE stmt USING _value;
  DEALLOCATE PREPARE stmt;
  CALL get_visitor(_id);
END$

DELIMITER ;
