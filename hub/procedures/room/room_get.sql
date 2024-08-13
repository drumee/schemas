
DELIMITER $
-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `room_get`$
-- DROP PROCEDURE IF EXISTS `room_get_next`$
CREATE PROCEDURE `room_get`(
  IN _device_id VARCHAR(64),
  IN _socket_id VARCHAR(64),
  IN _user_id VARCHAR(64),
  IN _room_id VARCHAR(16),
  IN _type VARCHAR(32)
)
BEGIN
  DECLARE _privilege TINYINT(2) DEFAULT 0;
  DECLARE _presenter TINYINT(4) DEFAULT 0;
  DECLARE _orphaned TINYINT(4) DEFAULT 0;
  DECLARE _hub_id VARCHAR(16) DEFAULT NULL;
  DECLARE _avatar_id VARCHAR(16) DEFAULT NULL;
  DECLARE _drumate_db VARCHAR(32) DEFAULT NULL;
  DECLARE _location VARCHAR(128) DEFAULT NULL;
  DECLARE _server VARCHAR(128) DEFAULT NULL;
  DECLARE _guest_name VARCHAR(128);
  DECLARE _email VARCHAR(128);
  DECLARE _redirect BOOLEAN;
  DECLARE _count INTEGER DEFAULT 0;
  DECLARE _org_perm TINYINT(4) DEFAULT 0b0100000;
  DECLARE _status VARCHAR(128) DEFAULT 'waiting';  
  DECLARE _role VARCHAR(128) DEFAULT 'listener';  
  DECLARE _area VARCHAR(128) DEFAULT NULL;  

  SELECT area, id FROM yp.entity WHERE db_name = DATABASE() INTO _area, _hub_id;

  IF _type = 'screen' OR _area = 'private' THEN 
    SET _org_perm = 0b0000010;
  END IF; 


  -- Clean gone sockets
  DELETE FROM room_attendee 
    WHERE socket_id NOT IN (SELECT id FROM yp.socket WHERE `state`='active');

  DELETE FROM yp.room WHERE hub_id=_hub_id AND 
    (presenter_id NOT IN (SELECT id FROM yp.socket WHERE `state`='active') OR presenter_id IS NULL);

  DELETE FROM yp.room_endpoint WHERE room_id NOT IN (SELECT id FROM yp.room);


  IF (_room_id IN('', '0')) THEN 
    SELECT NULL INTO _room_id;
  END IF;
  -- Only one single room with same type inside a same hub
  SELECT id, `status` FROM yp.room WHERE `type`=_type AND hub_id=_hub_id 
    INTO _room_id, _status;

  IF (_room_id IS NULL) THEN 
    SELECT room_id FROM room_attendee 
      WHERE `type`=_type
      LIMIT 1 INTO _room_id;
    SELECT IFNULL(_room_id, uniqueId()) INTO _room_id;
  END IF;

  SELECT user_permission(_user_id, _room_id) INTO _privilege; 

  SELECT `server`, `location` FROM yp.room_endpoint WHERE room_id=_room_id
    INTO _server, _location;

  -- SELECT COALESCE(e.server, u.server), COALESCE(e.location, u.location) 
  --   FROM yp.room_endpoint e LEFT JOIN yp.socket room_id=_room_id
  IF(_privilege&0b0000010) THEN 
    SELECT count(*) FROM yp.room WHERE id = _room_id INTO _count;

    -- The first attendee to enter select the media server instance as the endpoint 
    IF(_count = 0) THEN 
      IF _server IS NULL OR _location IS NULL THEN 
        SELECT s.server, s.location FROM yp.socket s WHERE
          s.state='active' AND s.id=_socket_id AND s.uid=_user_id
          INTO _server, _location; 
        REPLACE INTO yp.room_endpoint (`room_id`, `ctime`, `server`, `location`)
          VALUES(_room_id, UNIX_TIMESTAMP(), _server, _location);
      END IF; 
      IF (_privilege&_org_perm) THEN 
        REPLACE INTO yp.room (`hub_id`, `id`, `ctime`, `presenter_id`, `type`, `status`)
        VALUES(_hub_id, _room_id, UNIX_TIMESTAMP(), _socket_id, _type, 'started');
      ELSE 
        REPLACE INTO yp.room (`hub_id`, `id`, `ctime`, `type`, `status`)
        VALUES(_hub_id, _room_id, UNIX_TIMESTAMP(), _type, 'waiting');
      END IF;      
    END IF;
    IF(_privilege&_org_perm) THEN 
      -- Check existing presenter
      SELECT count(*) FROM yp.room r 
        INNER JOIN yp.socket s ON r.presenter_id=s.id 
        INNER JOIN yp.drumate d ON s.uid=d.id 
        WHERE r.type = _type AND hub_id=_hub_id AND s.state='active' 
        -- AND JSON_VALUE(`profile`, "$.connected") > 1 
        INTO _count; 
      -- SELECT 2 STEP, _count;
      -- No presenter yet. The first eligible one is the presenter
      IF(_count = 0) THEN 
        -- clean up zombie screen share
        DELETE FROM yp.room WHERE ctime < UNIX_TIMESTAMP() 
          AND `type` = 'screen' AND hub_id =  _hub_id;
        UPDATE yp.drumate SET `profile`=JSON_SET(`profile`, "$.connected", 2) WHERE id=_user_id;
        -- When the type is screen, keep same node as primary (meeting or webinar)
        IF _type = 'screen' THEN 
          SELECT e.server, e.location FROM yp.room_endpoint e 
            INNER JOIN yp.room r ON e.room_id = r.id 
            WHERE hub_id = _hub_id AND `type` != 'screen' ORDER BY e.ctime ASC LIMIT 1
            INTO _server, _location;
          REPLACE INTO yp.room_endpoint (`room_id`, `ctime`, `server`, `location`)
            VALUES(_room_id, UNIX_TIMESTAMP(), _server, _location);
        END IF;
      END IF;

    END IF;

    -- If there is an elegible presenter, set him
    SET @_role = 'listener';
    SELECT IF(presenter_id = _socket_id, 'presenter', 'listener')
      FROM yp.room WHERE hub_id =  _hub_id AND `type` = _type
      INTO @_role;
    REPLACE INTO room_attendee (
      id, 
      privilege,
      device_id, 
      socket_id, 
      room_id, 
      `type`,
      ctime, 
      `role`
    )
    VALUES(
      _user_id, 
      _privilege,
      _device_id, 
      _socket_id, 
      _room_id,
      _type,
      UNIX_TIMESTAMP(), 
      @_role
    );
  END IF;
  CALL room_access_next(_socket_id, _user_id, _room_id);
END$
DELIMITER ;

