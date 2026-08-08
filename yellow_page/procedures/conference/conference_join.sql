
DELIMITER $


-- =========================================================
-- new_conference
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_join`$
CREATE PROCEDURE `conference_join`(
  IN _args JSON,
  IN _metadata JSON 
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _socket_id VARCHAR(64) CHARACTER SET ascii;
  DECLARE _room_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _status VARCHAR(16) CHARACTER SET ascii DEFAULT 'waiting';
  DECLARE _org_perm TINYINT(4) DEFAULT 0b0010000;
  -- The write/edit bit of the member privilege word (ui lex/constants.js
  -- permission.write). view=0b0000011 and chat=0b0000111 lack it; edit=0b0001111,
  -- admin=0b0011111 and owner=0b0111111 carry it. Declared rather than inlined so
  -- the comparison is plain integer arithmetic (a bare 0b literal is a binary
  -- string in MariaDB), matching how _org_perm is already declared above.
  DECLARE _write_perm TINYINT(4) DEFAULT 0b0001000;
  DECLARE _role VARCHAR(128) DEFAULT 'attendee';  
  DECLARE _area VARCHAR(128) DEFAULT NULL;  
  DECLARE _db_name VARCHAR(128) DEFAULT NULL;  

  SELECT JSON_VALUE(_args, "$.hub_id") INTO _hub_id;
  SELECT JSON_VALUE(_args, "$.socket_id") INTO _socket_id;
  SELECT JSON_VALUE(_args, "$.room_id") INTO _room_id;

  SELECT area, db_name FROM yp.entity WHERE id=_hub_id INTO _area, _db_name;

  IF _room_id IS NULL THEN 
    SELECT c.room_id FROM yp.conference c INNER JOIN yp.socket s ON s.id=c.socket_id 
      WHERE hub_id=_hub_id AND `type` = JSON_VALUE(_metadata, "$.type") AND s.state='active'
      ORDER BY s.ctime DESC LIMIT 1 INTO _room_id;
  ELSE 
    SELECT JSON_MERGE_PATCH(metadata, _metadata) FROM conference
      WHERE room_id = _room_id AND `socket_id` = _socket_id INTO _metadata;
  END IF;

  SELECT IFNULL(_room_id, uniqueId()) INTO _room_id;

  SELECT `uid` FROM yp.socket WHERE id=_socket_id AND `state`='active' LIMIT 1 INTO _uid;

  SET @privilege = 0;
  IF _db_name IS NOT NULL THEN 
    SET @s = CONCAT("SELECT ", 
      _db_name, ".user_permission(", QUOTE(_uid), ", ", QUOTE(_room_id), ") INTO @privilege"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;


  -- STARTING a meeting is an edit-tier action; JOINING one is not. A member
  -- without the write bit (view=0b0000011, chat=0b0000111) may join a meeting
  -- somebody else is already running, but may not open one.
  --
  -- Enforced by falling into `SELECT 0 permission` below, which is the ONLY
  -- signal the client treats as a hard stop -- webrtc/room/index.js does
  --   if (!c.user || !c.user.permission) { stateMachine("permissionDenied"); return null; }
  -- The `status` and `role` columns are PRESENTATIONAL and must never be used as
  -- a gate: `status` only becomes a data-attribute plus the window `mode`, and
  -- `role` only enables host affordances (the meeting card, announce, end-for-all).
  -- Returning 'attendee'/'waiting' therefore does NOT stop a meeting.
  --
  -- "Already running" is the same hub+type active-conference test the branches
  -- below already use, so join keeps working exactly as before.
  --
  -- Areas: 'personal' is EXCLUDED -- that is the 1:1 P2P call, whose callee is
  -- granted privilege 3 by conference_invite, so gating it would break every
  -- P2P call. 'dmz' and 'public' are excluded too and keep today's rules.
  -- A caller that HAS the write bit never enters this block, so edit / admin /
  -- owner behaviour is byte-identical to before in every area.
  SET @deny_start = 0;
  IF _area IN ('private', 'share') AND (@privilege & _write_perm) <> _write_perm THEN
    SELECT COUNT(*) FROM yp.conference c INNER JOIN yp.socket s ON s.id = c.socket_id
      WHERE hub_id = _hub_id AND `type` = JSON_VALUE(_metadata, "$.type")
        AND `state` = 'active'
      INTO @live_meeting;
    IF @live_meeting = 0 THEN
      SET @deny_start = 1;
    END IF;
  END IF;

  IF _db_name IS NULL OR @privilege = 0 OR @deny_start = 1 THEN 
    SELECT 0 permission;
  ELSE  
    IF _area IN('personal', 'private') THEN
      SET @status = 'started'; 
      -- Internal meeting
      SELECT IF(count(*)=0, 'host', 'attendee') FROM yp.conference c INNER JOIN yp.socket s ON s.id= c.socket_id
        WHERE hub_id=_hub_id AND `type` = JSON_VALUE(_metadata, "$.type") AND `state` = 'active' INTO _role;
    ELSE 
      -- External meeting
      SET @status = 'waiting'; 
      SET @s = CONCAT ("SELECT IF(owner_id=", quote(_uid), ", 'started', 'waiting') FROM ", _db_name, 
        ".media WHERE id = ", quote(_room_id), " INTO @status");
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;

      -- Peer to peer call 
      IF @status = 'waiting' THEN 
        SET @s = CONCAT("SELECT IF(JSON_VALUE(`message`, '$.owner_id')=", QUOTE(_uid), 
          ", 'started', 'waiting') FROM ", _db_name, ".permission WHERE resource_id=", 
          QUOTE(_room_id), " LIMIT 1 INTO @status");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

      SELECT COUNT(*) FROM conference u INNER JOIN yp.socket s ON u.socket_id=s.id 
        WHERE u.room_id =_room_id AND s.state='active' AND `role`='host' INTO @alreadyStarted; 

      SELECT IF(count(*)=0, 'host', 'attendee') FROM yp.conference c INNER JOIN yp.socket s ON s.id= c.socket_id
        WHERE hub_id=_hub_id AND `type` = JSON_VALUE(_metadata, "$.type") AND `state` = 'active' INTO _role;

      IF @alreadyStarted THEN
        SELECT 'attendee', 'started' INTO _role, @status;
      ELSE
        SELECT IF(@status = 'started', 'host', 'attendee') INTO _role;
      END IF;
    END IF;

    SELECT JSON_MERGE_PATCH(_metadata, JSON_OBJECT(
      'role', _role, 
      'permission', @privilege,
      'area', _area
      )) INTO _metadata;
    REPLACE INTO yp.conference (room_id, socket_id, privilege, hub_id, metadata) 
      VALUES(_room_id ,_socket_id, @privilege, _hub_id, _metadata);
    -- SELECT _area, _status, @privilege, _uid, _role;
    SELECT 
      u.room_id,
      _hub_id hub_id,
      participant_id,
      participant_id attendee_id,
      coalesce(u.uid, c.uid, 'default') `uid`,
      audio, 
      video, 
      screen, 
      area,
      @status `status`,
      permission,
      `role`, 
      IFNULL(CASE 
        WHEN u.type = 'connect' THEN JSON_VALUE(quota, "$.contact_call")
        WHEN u.type = 'meeting' AND area = 'private' THEN JSON_VALUE(quota, "$.team_call")
        WHEN u.type = 'meeting' AND area = 'dmz' THEN JSON_VALUE(quota, "$.meeting_call")
        ELSE 0
      END, 0) quota,
      coalesce(guest_name, u.firstname, d.firstname) firstname, 
      coalesce(guest_name, u.firstname, d.firstname) username, 
      coalesce(u.lastname, d.lastname, '') lastname,
      s.id socket_id,
      s.server
      FROM yp.conference u 
        INNER JOIN yp.socket s ON u.socket_id=s.id 
        INNER JOIN yp.cookie c ON s.cookie=c.id
        LEFT JOIN yp.drumate d on c.uid=d.id
      WHERE u.room_id =_room_id AND hub_id=_hub_id AND s.state='active';
  END IF;
END$

DELIMITER ;