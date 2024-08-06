DELIMITER $

-- DROP PROCEDURE IF EXISTS `cookie_check_guest_next`$
DROP PROCEDURE IF EXISTS `cookie_check_guest`$
CREATE PROCEDURE `cookie_check_guest`(
 IN _sid varchar(90),
 IN _socket_id varchar(90)
)
BEGIN
  DECLARE _db_name VARCHAR(64);
  DECLARE _guest_id VARCHAR(64);
  DECLARE _drumate_name VARCHAR(120);
  DECLARE _home_dir VARCHAR(1000);
  DECLARE _home_id VARCHAR(1000);
  DECLARE _domain VARCHAR(1000);
  DECLARE _org_name VARCHAR(1000);
  DECLARE _avatar VARCHAR(1000);
  DECLARE _domain_id INTEGER;
  DECLARE _profile JSON;

  SELECT get_sysconf('guest_id') INTO _guest_id;
  SELECT db_name, home_dir, home_id, d.domain_id, o.link, o.name, avatar, d.profile
    FROM organisation o 
    INNER JOIN entity e on e.dom_id = o.domain_id 
    INNER JOIN drumate d on e.id = d.id  
    WHERE e.id = _guest_id
  INTO _db_name, _home_dir, _home_id, _domain_id, _domain, _org_name, _avatar, _profile;

  SELECT COALESCE(d.firstname, d.lastname, z.name) FROM socket s
    LEFT JOIN drumate d ON d.id=s.uid
    LEFT JOIN dmz_user z ON z.id=s.uid
    WHERE d.id!=_guest_id AND s.id=_socket_id
    GROUP BY(s.uid) LIMIT 1
    INTO _drumate_name; 

  -- SELECT GROUP_CONCAT(id) FROM yp.socket WHERE cookie=_sid INTO @_socket_id;

  SELECT DISTINCT * FROM 
    ( 
    SELECT 
    c.id AS session_id, 
    t.guest_id id, 
    t.id token, 
    0 AS signed_in,
    u.email AS username,
    _db_name AS db_name,
    _domain AS domain,
    _domain_id AS domain_id,
    _org_name org_name,
    _home_dir home_dir, 
    _home_id home_id,
    0 AS remit,
    _avatar AS avatar,
    "guest" AS connection,
    "guest" AS status,
    _profile AS profile,
    COALESCE(_drumate_name, u.name, c.guest_name) AS guest_name,
    IFNULL(u.name, 'Guest') AS firstname,
    IFNULL(u.name, 'Guest') AS lastname,
    u.name AS fullname,
    -- s.id AS socket_id,
    0 as is_support
    FROM cookie c 
    INNER JOIN dmz_token t on t.guest_id=c.uid
    INNER JOIN dmz_user u on u.id=c.uid
    -- LEFT JOIN socket s ON s.cookie = c.id 
    WHERE c.id=_sid 

    UNION 

    SELECT 
    c.id AS session_id, 
    t.guest_id id, 
    t.id token, 
    0 AS signed_in,
    u.id AS username,
    _db_name AS db_name,
    _domain AS domain,
    _domain_id AS domain_id,
    _org_name org_name,
    _home_dir home_dir, 
    _home_id home_id,
    0 AS remit,
    _avatar AS avatar,
    "guest" AS connection,
    "guest" AS status,
    _profile AS profile,
    COALESCE(_drumate_name, u.name, c.guest_name) AS guest_name,
    IFNULL(u.name, 'Guest') AS firstname,
    IFNULL(u.name, 'Guest') AS lastname,
    u.name AS fullname,
    -- s.id AS socket_id,
    0 as is_support
    FROM cookie c 
    INNER JOIN dmz_token t on t.guest_id=c.uid
    INNER JOIN dmz_media u on u.id=c.uid
    -- LEFT JOIN socket s ON s.cookie = c.id 
    WHERE c.id=_sid 
    ) A LIMIT 1;
END $


DELIMITER ;
