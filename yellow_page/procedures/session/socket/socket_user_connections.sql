DELIMITER $

DROP PROCEDURE IF EXISTS `socket_user_connections`$
CREATE PROCEDURE `socket_user_connections`(
  IN _key VARCHAR(80) CHARACTER SET ascii 
)
BEGIN
  -- DECLARE _id VARCHAR(16) CHARACTER SET ascii  DEFAULT NULL;
  -- SELECT `uid` FROM socket WHERE id=_uid AND `state`='active' 
  --   LIMIT 1 INTO _id;
  SELECT 
    1 isDrumate,
    s.id AS connection_id,
    s.id AS socket_id,
    e.id AS user_id,
    d.username as ident,
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
      WHERE e.id=_key AND s.state = 'active';
  -- UPDATE socket SET mtime = UNIX_TIMESTAMP() WHERE `uid`=_uid AND `uid`!='ffffffffffffffff';
END$

DELIMITER ;