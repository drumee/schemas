
DELIMITER $


-- DROP PROCEDURE IF EXISTS `analytic_transfer_users`$
DROP PROCEDURE IF EXISTS `analytic_transfer_dl`$
CREATE PROCEDURE `analytic_transfer_dl`(
  IN _json JSON
)
BEGIN
  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  CALL yp.parseDateRange(_json, _format, _start, _end);

  IF(JSON_VALUE(_json, "$.serie") = 'history') THEN 
    WITH data1 
    AS (
      SELECT FROM_UNIXTIME(ctime, _format) day,
      SUM(IFNULL(JSON_LENGTH(metadata, "$.download_by"), 0)) AS `count`
      FROM analytic_transfer GROUP BY day ASC
    )
    SELECT day, sum(count) OVER (ORDER BY day) AS `count`
    FROM data1 GROUP BY day ORDER BY day ASC;
  ELSE 
    SELECT FROM_UNIXTIME(ctime, _format) day,
    SUM(IFNULL(JSON_LENGTH(metadata, "$.download_by"), 0))AS `count`
    FROM analytic_transfer GROUP BY day ASC;
  END IF;
END $

DELIMITER ;
