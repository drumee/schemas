DELIMITER $

DROP PROCEDURE IF EXISTS `socket_user_server_connections`$
CREATE PROCEDURE `socket_user_server_connections`(
  IN _uid VARCHAR(80) CHARACTER SET ascii ,
  IN _server varchar(256)
)
BEGIN
  DECLARE _id VARCHAR(16) CHARACTER SET ascii  DEFAULT NULL;
  SELECT `uid` FROM socket WHERE id=_uid LIMIT 1 INTO _id;
  SELECT 
    1 isDrumate,
    s.id AS connection_id,
    s.id AS socket_id,
    e.id AS user_id,
    e.ident as ident,
    s.server,
    e.db_name,
    home_dir,
    remit,
    d.lang,
    d.avatar,
    e.status,
    d.profile,
    e.settings,
    -- disk_usage(e.id) AS disk_usage,
    -- quota,
    fullname
    FROM entity e 
      INNER JOIN drumate d ON e.id=d.id 
      INNER JOIN socket s  ON e.id=s.uid 
      WHERE e.id=IFNULL(_id, _uid) AND s.server = _server ;
  -- UPDATE socket SET mtime = UNIX_TIMESTAMP() WHERE `uid`=_uid AND `uid`!='ffffffffffffffff';
END$

DELIMITER ;


--  call yp.socket_user_server_connections('554bf212554bf219','51.75.130.67:23007')\G