
DELIMITER $

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_enter`$
CREATE PROCEDURE `conference_enter`(
  IN _socket_id VARCHAR(32),
  IN _status VARCHAR(32)
)
BEGIN
  DECLARE _master VARCHAR(16) DEFAULT '0';

  INSERT IGNORE INTO conference (`ctime`, `socket_id`, `status`) 
    SELECT UNIX_TIMESTAMP(), _socket_id, _status;

  -- SELECT IF(count(*), 'ready', 'waiting')
  --   FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
  --   ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
  --   WHERE permission & 0b0010000 AND resource_id='*' INTO _status;

  SELECT s.uid FROM conference INNER JOIN yp.socket s ON socket_id=s.id 
    WHERE status='started'
    LIMIT 1 INTO _master;

  -- SELECT IF(count(*), 'started', _status) 
  --   FROM conference  
  --   WHERE `status`='started' INTO _status;

  SELECT `uid`, `uid` AS id, firstname, lastname, fullname, 
    permission, c.ctime, 0 page, status, socket_id, s.server, _master master_id
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE resource_id="*"
    GROUP BY socket_id
    ORDER BY c.ctime ASC;
END$

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_enter_next`$
CREATE PROCEDURE `conference_enter_next`(
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _master VARCHAR(16) DEFAULT '0';

  DELETE FROM conference WHERE 
    (SELECT id FROM yp.socket s WHERE s.id=socket_id) IS NULL;

  REPLACE INTO conference (`ctime`, `socket_id`, `status`) 
    SELECT UNIX_TIMESTAMP(), _socket_id, 'ready';

  SELECT `uid`, `uid` AS id, firstname, lastname, fullname, 
    permission, c.ctime, 0 page, status, socket_id, s.server
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE resource_id="*"
    GROUP BY socket_id
    ORDER BY c.ctime ASC;
END$


-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_leave`$
CREATE PROCEDURE `conference_leave`(
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _master VARCHAR(16);
  DECLARE _uid VARCHAR(16);

  SELECT s.uid
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE permission & 0b0010000 AND resource_id='*' ORDER BY c.ctime ASC 
    LIMIT 1 INTO _master;
  SELECT `uid` FROM conference c INNER JOIN yp.socket s ON c.socket_id = s.id 
    WHERE `socket_id`=_socket_id INTO _uid;

  DELETE FROM conference WHERE `socket_id`=_socket_id;
  SELECT IF(_uid=_master, 'stopped', status) AS `status`, 
    `uid`, firstname, lastname, fullname, 
    permission, c.ctime, 0 page, socket_id, s.server
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE resource_id="*"
    GROUP BY socket_id
    ORDER BY c.ctime, permission ASC;
  -- IF _uid=_master THEN 
  --   DELETE FROM conference;
  -- END IF;
END$

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_show_peers`$
CREATE PROCEDURE `conference_show_peers`(
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _status VARCHAR(16);

  SELECT `uid`, firstname, lastname, fullname, 
    permission, c.ctime,  socket_id, s.server
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id
    WHERE socket_id <> _socket_id AND resource_id="*" GROUP BY socket_id
    ORDER BY c.ctime ASC;
END$

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_stop`$
CREATE PROCEDURE `conference_stop`(
)
BEGIN
  DELETE FROM conference;
END$

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_start`$
CREATE PROCEDURE `conference_start`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _status VARCHAR(255);
  SELECT IF(permission & 0b0010000, 'started', 'waiting')
    FROM permission 
    WHERE resource_id='*' AND entity_id=_uid INTO _status;

  UPDATE conference SET `status`=_status;
END$


-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `conference_get_room`$
DROP PROCEDURE IF EXISTS `conference_get`$

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `meeting_create_room`$
DROP PROCEDURE IF EXISTS `conference_create_room`$

-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `meeting_get_room`$

DELIMITER ;
