
DELIMITER $


DROP PROCEDURE IF EXISTS `analytic_hub_users`$
CREATE PROCEDURE `analytic_hub_users`(
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
      count(*) u
      FROM yp.drumate d INNER JOIN yp.entity e USING(id) WHERE 
        JSON_VALUE(profile, "$.profile_type")='hub' AND `status`="active" 
      GROUP BY day ASC
    )
    SELECT day, sum(u) OVER (ORDER BY day) AS `count` 
      FROM data1 GROUP BY day ORDER BY day ASC;
  ELSE 
    DROP TABLE IF EXISTS __tmp_services;
    CREATE TEMPORARY TABLE __tmp_services AS SELECT
      ctime, json_value(args, "$.hub_id") `uid` FROM services_log WHERE name='desk.home';

    SELECT FROM_UNIXTIME(s.ctime, _format) day, 
    count(DISTINCT d.id) AS `count`
    FROM yp.drumate d INNER JOIN __tmp_services s on d.id = s.uid GROUP BY day ASC;
  END IF;

END $

DELIMITER ;

