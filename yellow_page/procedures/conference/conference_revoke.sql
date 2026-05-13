DELIMITER $


-- =========================================================
-- update_conference
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_revoke`$
CREATE PROCEDURE `conference_revoke`(
  IN _hub_id VARCHAR(64) CHARACTER SET ascii,
  IN _room_id VARCHAR(64)  CHARACTER SET ascii,
  IN _guest_id VARCHAR(64)  CHARACTER SET ascii
)
BEGIN
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(128) DEFAULT NULL;
  DECLARE _username VARCHAR(128) DEFAULT NULL;
  DECLARE _firstname VARCHAR(128) DEFAULT NULL;

  DELETE FROM conference WHERE room_id = _room_id AND `uid` = _guest_id;

  SELECT db_name, owner_id FROM entity e INNER JOIN hub h USING(id) WHERE id=_hub_id INTO _db_name, _owner_id;

  -- Revoke permission only when the hub side resolves (team / shared hubs);
  -- P2P calls keep hub_id = caller's user id, which may not have a matching
  -- hub row. In that case skip the permission cleanup but still return the
  -- callee's sockets so the service-layer can inform the peer.
  IF _db_name IS NOT NULL AND _owner_id IS NOT NULL THEN
    SET @s = CONCAT("CALL ", _db_name, ".permission_revoke(",
      QUOTE(_room_id), ", ", QUOTE(_guest_id), ")"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  IF _owner_id IS NOT NULL THEN
    SELECT fullname, firstname FROM drumate WHERE id = _owner_id INTO _username, _firstname;
  ELSE
    -- Fall back to the caller's own drumate row so the result rows still
    -- carry a sensible username / display for the WS event.
    SELECT id, fullname, firstname FROM drumate WHERE id = _hub_id INTO _owner_id, _username, _firstname;
  END IF;

  -- ALWAYS return the callee's active sockets so the caller's `inform()`
  -- can broadcast `conference.revoke` to the ringing peer, even when the
  -- permission lookup above is a no-op (typical P2P case).
  SELECT
    _room_id room_id,
    _owner_id `uid`,
    _username username,
    _username display,
    _owner_id drumate_id,
    _owner_id entity_id,
    _firstname firstname,
    id socket_id,
    `server`
    FROM socket WHERE `uid`=_guest_id AND `state` = 'active';

END$


DELIMITER ;
