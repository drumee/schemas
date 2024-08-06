DELIMITER $

  -- DECLARE _my_sockets INTEGER;
  -- SELECT count(1) 
  --   FROM yp.entity e INNER JOIN yp.socket s ON e.id=s.uid AND e.db_name = database()
  --   INTO _my_sockets;




-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `socket_bind_next`$
CREATE PROCEDURE `socket_bind_next`(
  IN _id VARCHAR(32),
  IN _uid VARCHAR(16),
  IN _cid VARCHAR(64),
  IN _server VARCHAR(258)
)
BEGIN
  REPLACE 
    INTO socket(`id`, `uid`, `cookie`, `ctime`, `mtime`, `server`) 
    VALUE(_id, _uid, _cid, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), _server);
  SELECT 
    c.id AS session_id,
    e.id AS user_id,
    e.id AS uid,
    e.ident as username,
    e.ident as ident,
    db_name,
    home_dir,
    domain,
    e.status,
    c.status as connection,
    e.settings,
    disk_usage(e.id) AS disk_usage
    FROM socket s INNER JOIN (entity e, cookie c) ON e.id=c.uid AND e.id=s.uid
      WHERE s.id=_id;

END$


-- =========================================================
-- 
-- =========================================================



-- -- =========================================================
-- -- 
-- -- =========================================================
-- DROP PROCEDURE IF EXISTS `socket_bind`$
-- CREATE PROCEDURE `socket_bind`(
--   IN _id VARCHAR(32),
--   IN _uid VARCHAR(16),
--   IN _server VARCHAR(258)
-- )
-- BEGIN
--   REPLACE 
--     INTO socket(`id`, `uid`, `ctime`, `mtime`, `server`) 
--     VALUE(_id, _uid,  UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), _server);
--   SELECT 
--     c.id AS session_id,
--     e.id AS user_id,
--     e.id AS uid,
--     e.ident as username,
--     e.ident as ident,
--     db_name,
--     home_dir,
--     domain,
--     e.status,
--     c.status as connection,
--     e.settings,
--     disk_usage(e.id) AS disk_usage
--     FROM socket s INNER JOIN (entity e, cookie c) ON e.id=c.uid AND e.id=s.uid
--       WHERE s.id=_id;
-- END$


-- =========================================================
-- 
-- =========================================================


-- =========================================================
-- 
-- =========================================================


-- =========================================================
-- 
-- =========================================================
