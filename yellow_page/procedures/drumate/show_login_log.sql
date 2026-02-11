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
    JSON_VALUE(args, "$.geodata.city") city,
    JSON_VALUE(args, "$.geodata.timezone") timezone,
    COALESCE(JSON_VALUE(args, "$.geodata.ip"), JSON_VALUE(args, "$.ip")) ip,
    JSON_VALUE(headers, "$.user-agent") ua,
    IF(`name`='yp.logout', ctime, null) outtime,
    IF(`name`='yp.login', ctime, null) intime
  FROM services_log WHERE 
    `uid`=_uid AND (`name`='yp.login' OR `name`='yp.logout') 
  ORDER BY sys_id DESC LIMIT _offset, _range; 
END$


DELIMITER ;