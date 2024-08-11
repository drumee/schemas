
DELIMITER $


DROP PROCEDURE IF EXISTS `analytic_drumates`$
CREATE PROCEDURE `analytic_drumates`(
  IN _json JSON
)
BEGIN
    DECLARE _format VARCHAR(120);
    -- DECLARE _start INT(11) unsigned;
    DECLARE _epoch INT(11) unsigned;
    -- DECLARE _end INT(11) unsigned;

    SELECT UNIX_TIMESTAMP(STR_TO_DATE('2020-04-01', "%Y-%m-%d")) INTO _epoch;
    WITH data1 
    AS (
      SELECT FROM_UNIXTIME(ctime, "%y-%m-%d") day,
      count(*) drumates
      FROM yp.drumate d INNER JOIN yp.entity e USING(id) WHERE 
      -- JSON_VALUE(profile, "$.insider") IS NOT NULL AND
      ctime >= _epoch AND e.status IN('active')
      GROUP BY day ASC
    )
    SELECT day, sum(drumates) OVER (ORDER BY day) AS `count` 
      FROM data1 GROUP BY day ORDER BY day ASC;

END $
DELIMITER ;