DELIMITER $


DROP PROCEDURE IF EXISTS `remove_member`$
CREATE PROCEDURE `remove_member`(
  IN _key  VARCHAR(80)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(80);
  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;
  SELECT id, db_name  FROM yp.entity WHERE id=_key INTO _uid, _drumate_db;
  -- DELETE FROM member WHERE id = _uid;
  DELETE FROM permission WHERE entity_id = _uid;
  SET @s1 = CONCAT("DELETE FROM `", _drumate_db, "`.permission ",
    " WHERE resource_id = ", quote(_hub_id), ";");
  SET @s2 = CONCAT("DELETE FROM `", _drumate_db, "`.media ",
    " WHERE id = ", quote(_hub_id), ";");
  PREPARE stmt FROM @s1;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  PREPARE stmt FROM @s2;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  SELECT _uid AS id, 0 AS permission;
END $
DELIMITER ;
