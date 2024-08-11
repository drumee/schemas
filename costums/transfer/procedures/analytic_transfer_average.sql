
DELIMITER $


-- DROP PROCEDURE IF EXISTS `analytic_transfer_usage`$
DROP PROCEDURE IF EXISTS `analytic_transfer_average`$
CREATE PROCEDURE `analytic_transfer_average`(
  IN _json JSON
)
BEGIN
  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  DECLARE _service VARCHAR(1000);
  DECLARE _hub_id VARCHAR(16);

  CALL yp.parseDateRange(_json, _format, _start, _end);
  SELECT IFNULL(json_value(_json, "$.service"), '') INTO _service;
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS _average; 
  CREATE TEMPORARY TABLE _average  AS  SELECT 
    from_unixtime(ctime, _format) date_time, 
    ctime, 
    round(AVG(json_value(metadata, "$.size"))/(1024*1024)) AS average, 
    count(*) `count`
  FROM analytic_transfer  
    WHERE ctime <= _end AND ctime >= _start
  GROUP BY date_time ORDER BY date_time ASC;
  ALTER TABLE _average ADD UNIQUE KEY date_time (date_time);

  DROP TABLE IF EXISTS _service; 
  CREATE TEMPORARY TABLE _service  AS  
  SELECT 
  FROM_UNIXTIME(ctime, _format) date_time,
  ctime,
  count(*) AS `count`
  FROM yp.services_log WHERE hub_id = _hub_id AND `name` = _service 
    AND ctime <= _end AND ctime >= _start
    GROUP BY date_time ASC;
  ALTER TABLE _service ADD UNIQUE KEY date_time (date_time);
  SELECT 
    COALESCE(a.date_time, s.date_time) AS day, 
    COALESCE(a.ctime, s.ctime) AS ctime,
    CAST(FROM_UNIXTIME(COALESCE(a.ctime, s.ctime), "%H") AS INT) hour, 
    average, 
    a.count, 
    IFNULL(s.count, 0) AS connection
    FROM _average a LEFT JOIN _service s 
    ON s.date_time = a.date_time ORDER BY ctime ASC;
  DROP TABLE IF EXISTS _service; 
  DROP TABLE IF EXISTS _average; 
END $

DELIMITER ;