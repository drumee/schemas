
DELIMITER $


-- =========================================================
-- update_conference
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_get_caller`$
CREATE PROCEDURE `conference_get_caller`(
  IN _arg JSON
)
BEGIN
  DECLARE _caller_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _callee_id VARCHAR(128) DEFAULT NULL;  
  DECLARE _hub_id VARCHAR(128) DEFAULT NULL;  
  DECLARE _username VARCHAR(128) DEFAULT NULL;  
  DECLARE _firstname VARCHAR(128) DEFAULT NULL;  
  DECLARE _caller_db VARCHAR(128) DEFAULT NULL;  

  SELECT JSON_VALUE(_arg, "$.callee_id") INTO _callee_id;
  SELECT JSON_VALUE(_arg, "$.caller_id") INTO _caller_id;

  SELECT e.db_name, h.id FROM yp.hub h INNER JOIN yp.entity e on e.id=h.id 
    WHERE h.owner_id=_caller_id AND `serial`=0 INTO _caller_db, _hub_id;

  -- SELECT _caller_db, _hub_id;
  SELECT fullname, firstname FROM drumate WHERE id=_caller_id INTO _username, _firstname;


  SET @message = NULL;
  IF _caller_db IS NOT NULL THEN 
    -- Check if there may be cross invitation
    SET @s = CONCAT("SELECT message, resource_id FROM ", _caller_db, ".permission WHERE ", 
      "expiry_time > UNIX_TIMESTAMP() AND JSON_VALUE(message, '$.type')='rendez-vous' ",
      "AND JSON_VALUE(message, '$.owner_id')=", QUOTE(_caller_id), " AND entity_id=", QUOTE(_callee_id),
      " ORDER BY ctime DESC LIMIT 1 INTO @message, @room_id"
    );
    -- SELECT @s stm;
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    -- Got cros invitation 
    IF @message IS NOT NULL AND @room_id IS NOT NULL THEN 
      SELECT 
        _hub_id hub_id,
        @room_id room_id,
        @room_id nid,
        _username username,
        _username display,
        _firstname firstname,
        _caller_id `uid`,
        _caller_id drumate_id,
        _caller_id entity_id;
    ELSE 
      SELECT NULL room_id;
    END IF;
  ELSE 
    SELECT NULL room_id;
  END IF;
END$


DELIMITER ;