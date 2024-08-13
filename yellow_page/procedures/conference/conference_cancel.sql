
DELIMITER $


-- =========================================================
-- update_conference
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_cancel`$
CREATE PROCEDURE `conference_cancel`(
  IN _room_id VARCHAR(64),
  IN _socket_id VARCHAR(64)
)
BEGIN
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(128) DEFAULT NULL;  

  SELECT hub_id FROM conference WHERE room_id = _room_id AND socket_id = _socket_id INTO _hub_id;
  DELETE FROM conference WHERE room_id = _room_id AND socket_id = _socket_id;

  SELECT db_name, owner_id FROM entity e INNER JOIN hub h USING(id) WHERE id=_hub_id INTO _db_name, _owner_id;
  IF _db_name IS NOT NULL AND _owner_id IS NOT NULL THEN 
    SET @s = CONCAT("SELECT s.id socket_id, s.server, p.entity_id, ", QUOTE(_room_id), "room_id ",
      "FROM yp.socket s INNER JOIN ",  
      _db_name,
      ".permission p ON s.uid=p.entity_id WHERE s.state='active' AND p.resource_id=", 
      QUOTE(_room_id)
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @s = CONCAT("DELETE FROM ", _db_name, ".permission WHERE resource_id=", 
      QUOTE(_room_id), " AND JSON_VALUE(message, '$.owner_id')=", QUOTE(_owner_id)
    ); 
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

 
END$


DELIMITER ;