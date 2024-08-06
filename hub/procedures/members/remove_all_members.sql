DELIMITER $
DROP PROCEDURE IF EXISTS `remove_all_members`$
CREATE PROCEDURE `remove_all_members`(
  IN _keep_id  VARCHAR(16)
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(40);
  DECLARE _uid VARCHAR(16);
  DECLARE _perm TINYINT(2);
  DECLARE _members CURSOR FOR SELECT entity_id, permission FROM permission WHERE entity_id != '*';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1; 
  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;
  OPEN _members;

  WHILE NOT _done DO
    FETCH _members INTO _uid, _perm;
    IF _uid != _keep_id THEN
      SELECT db_name  FROM yp.entity WHERE id=_uid INTO  _drumate_db;
     IF (_drumate_db IS NOT NULL) THEN 
        SET @s = CONCAT(
          "DELETE FROM `", _drumate_db, "`.permission WHERE resource_id = ", quote(_hub_id), ";"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SET @s = CONCAT(
          "DELETE FROM `", _drumate_db, "`.media WHERE id = ", quote(_hub_id), ";"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
      SELECT NULL INTO _drumate_db; 
    END IF;
  END WHILE;
  CLOSE _members;
  DELETE FROM permission WHERE entity_id != _keep_id AND entity_id != '*' ;
END $

DELIMITER ;
