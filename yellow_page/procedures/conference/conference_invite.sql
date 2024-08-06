
DELIMITER $
DROP PROCEDURE IF EXISTS `conference_invite`$
CREATE PROCEDURE `conference_invite`(
  IN _arg JSON
)
BEGIN
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(128) DEFAULT NULL;  
  DECLARE _username VARCHAR(128) DEFAULT NULL;  
  DECLARE _firstname VARCHAR(128) DEFAULT NULL;  
  DECLARE _sockets INT(8) UNSIGNED DEFAULT 0;

  SELECT COUNT(*) FROM socket WHERE `uid`=JSON_VALUE(_arg, "$.guest_id") AND `state` = 'active' INTO _sockets;
  IF _sockets = 0 THEN 
    SELECT 1 `offline`;
  ELSE
    SELECT db_name, owner_id FROM entity e INNER JOIN hub h USING(id) 
      WHERE id=JSON_EXTRACT(_arg, "$.hub_id") INTO _db_name, _owner_id;
    SELECT fullname, firstname FROM drumate WHERE id = _owner_id INTO _username, _firstname;

    SELECT JSON_MERGE_PATCH(_arg, JSON_OBJECT(
      'room_id', IFNULL(JSON_VALUE(_arg, "$.room_id"), uniqueId()), 
      'owner_id', _owner_id,
      'type', 'rendez-vous'
    )) INTO @metadata;

    IF _db_name IS NOT NULL AND _owner_id IS NOT NULL THEN 
      SET @s = CONCAT("DELETE FROM ", _db_name, ".permission WHERE ", 
      "expiry_time >0 AND expiry_time < UNIX_TIMESTAMP() AND JSON_VALUE(message, '$.type')='rendez-vous'"
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;

      SET @s = CONCAT("CALL ", _db_name, ".permission_grant(", 
        JSON_EXTRACT(@metadata, "$.room_id"), ",",
        JSON_EXTRACT(@metadata, "$.guest_id"), ",",
        24, ",",
        3, ",",
        QUOTE('no_traversal'), ",",
        QUOTE(@metadata), ")"
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;
    SELECT 
      JSON_VALUE(@metadata, "$.room_id") room_id,
      _owner_id `uid`,
      _username username,
      _username display,
      _owner_id drumate_id,
      _owner_id entity_id,
      _firstname firstname,
      id socket_id,
      `server`
      FROM socket WHERE `uid`=JSON_VALUE(@metadata, "$.guest_id") AND `state` = 'active';
  END IF;
END$


DELIMITER ;