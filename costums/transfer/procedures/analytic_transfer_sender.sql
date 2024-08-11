
DELIMITER $


-- DROP PROCEDURE IF EXISTS `analytic_transfer_users`$
DROP PROCEDURE IF EXISTS `analytic_transfer_sender`$
CREATE PROCEDURE `analytic_transfer_sender`(
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
      SELECT DISTINCT json_value(metadata, "$.sender_hash") sender_hash,
      FROM_UNIXTIME(ctime, _format) day, 
      count(*) `count`
      FROM analytic_transfer GROUP BY day
    )
    SELECT day, sum(`count`) OVER (ORDER BY day) AS `count`
    FROM data1 GROUP BY day ORDER BY day ASC;
  ELSE 
    SELECT DISTINCT json_value(metadata, "$.sender_hash") sender_hash,
    FROM_UNIXTIME(ctime, _format) day,
    count(*) `count`
    FROM analytic_transfer GROUP BY day ASC;
  END IF;
END $

DELIMITER ;
