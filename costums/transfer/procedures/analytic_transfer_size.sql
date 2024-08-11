
DELIMITER $


-- DROP PROCEDURE IF EXISTS `analytic_transfer_usage`$
DROP PROCEDURE IF EXISTS `analytic_transfer_size`$
CREATE PROCEDURE `analytic_transfer_size`(
  IN _json JSON
)
BEGIN
  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  SELECT IFNULL(json_value(_json, "$.time_format"), "%y-%m-%d") INTO _format;

  IF(JSON_VALUE(_json, "$.serie") = 'history') THEN 
    WITH data1 
    AS (
      SELECT from_unixtime(ctime, _format) day, 
        round(sum(json_value(metadata, "$.size"))/(1024*1024)) AS size
      FROM analytic_transfer GROUP BY day ASC
    )
    SELECT day, sum(size) OVER (ORDER BY day) AS size
    FROM data1 GROUP BY day ORDER BY day ASC;
  ELSE 
    SELECT from_unixtime(ctime, _format) day, 
      round(sum(json_value(metadata, "$.size"))/(1024*1024)) AS size, 
      count(*) `count`
    FROM analytic_transfer GROUP BY day ORDER BY day ASC;
  END IF;
END $

DELIMITER ;