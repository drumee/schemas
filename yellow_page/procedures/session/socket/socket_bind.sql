DELIMITER $

-- DROP PROCEDURE IF EXISTS `socket_bind_next`$
DROP PROCEDURE IF EXISTS `socket_bind`$
CREATE PROCEDURE `socket_bind`(
  IN _args JSON
)
BEGIN

  DECLARE _id VARCHAR(32) CHARACTER SET ascii;
  DECLARE _sid VARCHAR(64) CHARACTER SET ascii;
  DECLARE _endpoint VARCHAR(256) CHARACTER SET ascii;
  DECLARE _path VARCHAR(256);
  DECLARE _token VARCHAR(256) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _type VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _cookie_id VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _status VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _state VARCHAR(64) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _ts   INT(11) DEFAULT 0;

  SELECT JSON_VALUE(_args, "$.id") INTO _id;
  SELECT JSON_VALUE(_args, "$.sid") INTO _sid;
  SELECT JSON_VALUE(_args, "$.endpoint") INTO _endpoint;
  SELECT JSON_VALUE(_args, "$.token") INTO _token;

  SELECT UNIX_TIMESTAMP() INTO _ts;

  IF _token IS NOT NULL THEN
    SELECT `type`, id FROM authn  WHERE `token`=_token 
      INTO _type, _sid;
    IF _sid IS NOT NULL THEN
      SELECT id, `status`, `uid` FROM cookie WHERE id = _sid 
        INTO _cookie_id, _status, _uid;
    END IF;
    IF _type='guest' THEN
      SELECT get_sysconf('guest_id') INTO _uid;
    END IF;
    DELETE FROM authn WHERE `token`=_token;
  ELSE 
    SELECT id, `status`, `uid` FROM cookie WHERE id = _sid 
      INTO _cookie_id, _status, _uid;
  END IF;

  IF _cookie_id IS NULL THEN
    SELECT nobody_id() INTO _uid;
    INSERT INTO cookie (`id`, `uid`, `ctime`, `mtime`, `status`) 
    VALUES(_sid, _uid, _ts, _ts, 'socket');
    SELECT _sid INTO _cookie_id;
  END IF;

  SELECT `state` FROM socket WHERE cookie=_cookie_id AND id=_id 
    AND `uid`=_uid INTO _state;
  IF _state IS NULL THEN 
    REPLACE INTO socket (`id`, `uid`, `cookie`, `ctime`, `server`, `location`, `state`) 
    VALUES( _id, _uid, _cookie_id, _ts,  _endpoint, _path, 'active');
    REPLACE INTO socket_active (`id`, `timestamp`) VALUES( _id, _ts);
  ELSE 
    UPDATE socket 
    SET id = _id,
      cookie=_cookie_id, 
      ctime=_ts, 
      `server`= _endpoint,
      `location`= _path,
      `state`= 'active'
    WHERE  id = _id;
  END IF;

  SELECT 
    _cookie_id AS session_id,
    COALESCE(d.id, u.id) as user_id,
    COALESCE(d.id, u.id) as uid,
    COALESCE(d.username, u.email) as username,
    COALESCE(d.username, u.email) as ident,
    COALESCE(e.db_name, yp.get_sysconf('nobody_db')) as db_name,
    COALESCE(e.home_dir, yp.get_sysconf('nobody_home_dir')) AS home_dir,
    _status as `connection`,
    s.id as socket_id
    FROM socket s 
      LEFT JOIN entity e ON e.id=s.uid
      LEFT JOIN drumate d ON d.id=s.uid
      LEFT JOIN dmz_user u ON u.id=s.uid
  WHERE s.id=_id AND s.state='active' ;

END $



DELIMITER ;
