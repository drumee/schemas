DELIMITER $

DROP PROCEDURE IF EXISTS `socket_bind_token`$
CREATE PROCEDURE `socket_bind_token`(
  IN _id VARCHAR(32) CHARACTER SET ascii,
  IN _cid VARCHAR(64) CHARACTER SET ascii,
  IN _server VARCHAR(256),
  IN _location VARCHAR(256)
)
BEGIN
  -- ???
  -- DECLARE _uid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  -- DECLARE _cookie_id VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  -- DECLARE _status VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  -- DECLARE _state VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  -- DECLARE _ts   INT(11) DEFAULT 0;
  

  -- SELECT id, `status`, `uid` FROM cookie WHERE id = _cid 
  --   INTO _cookie_id, _status, _uid;

  -- IF _cookie_id IS NULL OR _status NOT IN('ok', 'guest') THEN
  --   SELECT 1 failed, 'COOKIE_NOT_FOUND' reason, _cid cookie;
  -- ELSE 
  --   SELECT `state` FROM socket WHERE cookie=_cookie_id AND id=_id 
  --     AND `uid`=_uid INTO _state;
  --   IF _state IS NULL THEN 
  --     SELECT UNIX_TIMESTAMP() INTO _ts;
  --     REPLACE INTO socket (`id`, `uid`, `cookie`, `ctime`, `server`, `location`, `state`) 
  --     VALUES( _id, _uid, _cookie_id, _ts,  _server, _location, 'active');

  --   ELSE 
  --     SELECT UNIX_TIMESTAMP() INTO _ts;
  --     UPDATE socket 
  --     SET id = _id,
  --       cookie=_cookie_id, 
  --       ctime=_ts, 
  --       `server`= _server,
  --       `location`= _location,
  --       `state`= 'active'
  --     WHERE  id = _id;
  --   END IF;

  --   SELECT 
  --     _cookie_id AS session_id,
  --     COALESCE(d.id, u.id) as user_id,
  --     COALESCE(d.id, u.id) as uid,
  --     COALESCE(d.username, u.email) as username,
  --     COALESCE(d.username, u.email) as ident,
  --     COALESCE(e.db_name, yp.get_sysconf('nobody_db')) as db_name,
  --     COALESCE(e.home_dir, yp.get_sysconf('nobody_home_dir')) AS home_dir,
  --     _status as connection,
  --     s.id as socket_id
  --     FROM socket s 
  --       LEFT JOIN entity e ON e.id=s.uid
  --       LEFT JOIN drumate d ON d.id=s.uid
  --       LEFT JOIN dmz_user u ON u.id=s.uid
  --     WHERE s.id=_id AND s.state='active' ;
  -- END IF;

END $



DELIMITER ;
