
DELIMITER $


DROP PROCEDURE IF EXISTS `analytics_log`$
CREATE PROCEDURE `analytics_log`(
    IN _name varchar(128),
    IN _args json,    
    IN _uid varchar(16),
    IN _hub_id varchar(16),
    IN _headers JSON
)
BEGIN

  INSERT INTO services_log SELECT
    null,
    _name,
    _args,
    _uid,
    _hub_id,
    _headers,
    UNIX_TIMESTAMP();
  SELECT sys_id FROM services_log ORDER BY sys_id LIMIT 1;
END $

DELIMITER ;