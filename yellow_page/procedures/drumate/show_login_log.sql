DELIMITER $

DROP PROCEDURE IF EXISTS `show_login_log`$
CREATE PROCEDURE `show_login_log`(
  IN _uid VARCHAR(16),
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  -- DROP TABLE IF EXISTS __tmp_log;'42d21f1242d21f1a'
  SELECT 
    _page as `page`,
    JSON_UNQUOTE(JSON_EXTRACT(args, "$.geodata.city")) city,
    JSON_UNQUOTE(JSON_EXTRACT(args, "$.geodata.timezone")) timezone,
    JSON_UNQUOTE(JSON_EXTRACT(args, "$.geodata.ip")) ip,
    JSON_UNQUOTE(JSON_EXTRACT(headers, "$.user-agent")) ua,
    IF(`name`='yp.logout', ctime, null) outtime,
    IF(`name`='yp.login', ctime, null) intime
  FROM services_log WHERE 
    `uid`=_uid AND (`name`='yp.login' OR `name`='yp.logout') 
  ORDER BY sys_id DESC LIMIT _offset, _range; 

  -- SELECT  
  --   _page as `page`,
  --   cookie_id ,
  --   intime,
  --   outtime,
  --   read_json_object(l.metadata, "timezone") timezone,
  --   JSON_UNQUOTE(JSON_EXTRACT(args, "$.geodata.city")) city,
  --   read_json_object(l.metadata, "ip") ip,
  --   metadata,
  --   CASE WHEN c.id IS NULL THEN 'inactive' ELSE 'active' END  status 
  -- FROM 
  -- login_log l
  -- LEFT JOIN yp.cookie  c ON c.id=l.cookie_id AND c.uid = _uid
  -- WHERE l.intime IS NOT NULL
  -- ORDER BY l.sys_id DESC  LIMIT _offset, _range; 
END$


DELIMITER ;