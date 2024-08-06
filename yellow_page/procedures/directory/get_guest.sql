DELIMITER $


DROP PROCEDURE IF EXISTS `get_guest`$
CREATE PROCEDURE `get_guest`(
  IN _key VARCHAR(512)
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db_name VARCHAR(64);
  DECLARE _home_dir VARCHAR(1000);
  DECLARE _home_id VARCHAR(1000);
  DECLARE _domain VARCHAR(1000);
  DECLARE _org_name VARCHAR(1000);
  DECLARE _avatar VARCHAR(1000);
  DECLARE _domain_id INTEGER;
  DECLARE _profile JSON;

  SELECT e.id, db_name, home_dir, home_id, d.domain_id, o.link, o.name, avatar, d.profile
    FROM organisation o 
    INNER JOIN entity e on e.dom_id = o.domain_id 
    INNER JOIN drumate d on e.id = d.id  
  WHERE e.id='ffffffffffffffff'
  INTO _hub_id, _db_name, _home_dir, _home_id, _domain_id, _domain, _org_name, _avatar, _profile;


  SELECT
    u.id,
    _hub_id as hub_id,
    u.email AS ident,
    u.email username,
    _db_name db_name,
    _home_dir,
    0 AS remit,
    UNIX_TIMESTAMP() mtime,
    UNIX_TIMESTAMP() ctime,
    _domain AS domain,
    'en' lang,
    'default' avatar,
    'guest' status,
    _profile profile,
    null settings,
    0 disk_usage,
    0 quota,
    IFNULL(u.name, u.email) firstname,
    IFNULL(u.name, u.email) lastname,
    IFNULL(u.name, u.email) fullname
  FROM dmz_user u
    WHERE u.id=_key OR u.email=_key;
    
END$

DELIMITER ;