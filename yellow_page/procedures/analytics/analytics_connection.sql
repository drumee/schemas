
DELIMITER $


DROP PROCEDURE IF EXISTS `analytics_connection`$
CREATE PROCEDURE `analytics_connection`(
  IN _json JSON
)
BEGIN
  DECLARE _probe_id VARCHAR(16);
  DECLARE _domain VARCHAR(1000);
  DECLARE _domains json;
  DECLARE _service VARCHAR(1000);
  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  DECLARE _epoch INT(11) unsigned;
  DECLARE _drumates INT(11) unsigned;
  DECLARE _i INT DEFAULT 0;

  DROP TABLE IF EXISTS _tmp_analytics;

  SELECT NAME FROM domain WHERE id=1 INTO _domain;
  CALL yp.parseDateRange(_json, _format, _start, _end);


  CREATE TEMPORARY TABLE _tmp_analytics(
    `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `ctime` int(11) unsigned NOT NULL,
    `date_time` varchar(128) CHARACTER SET ascii DEFAULT '',
    `day` varchar(128) CHARACTER SET ascii DEFAULT '',
    `count` int(11) unsigned DEFAULT 1,
    `name` varchar(128) CHARACTER SET ascii DEFAULT '',
    PRIMARY KEY (`sys_id`)
  );
  
  INSERT INTO _tmp_analytics SELECT 
    sys_id,
    ctime,
    FROM_UNIXTIME(ctime, _format),
    FROM_UNIXTIME(ctime, "%Y-%m-%d"),
    1,
    `name`
    FROM services_log WHERE 
      `name` IN (
        '', 
        'butler.b2b_signup_password', 
        'butler.b2c_signup_password', 
        'butler.signup', 
        'desk.home'
      ) AND
      (ctime <= _end AND ctime >= _start);

  UPDATE _tmp_analytics SET `name`='index' WHERE `name`='';

  SELECT
    GROUP_CONCAT(DISTINCT
      CONCAT(
        "SUM(IF(`name`=", QUOTE(`name`), ", 1, 0)) AS `", `name`, "` "
      )
    ) INTO @sql
  FROM _tmp_analytics;

  SET @sql = CONCAT(@sql, ", SUM(IF(`name`='account', count, 0)) AS account ");

  INSERT INTO _tmp_analytics SELECT 
    null, 
    ctime, 
    FROM_UNIXTIME(ctime, _format),
    FROM_UNIXTIME(ctime, "%Y-%m-%d"),
    count(*),
    'account'
    FROM entity WHERE (ctime <= _end AND ctime >= _start) AND 
    `status`="active" AND `type`='drumate' GROUP BY ctime;


  DROP TABLE IF EXISTS _tmp_results;
  SET @sql = CONCAT(
    'CREATE TEMPORARY TABLE _tmp_results AS SELECT ctime, date_time, ', 
    'CAST(FROM_UNIXTIME(ctime, "%h") AS INT) hour, ',
    'FROM_UNIXTIME(ctime, "%Y-%m-%d") AS day, ',
    @sql, 
    'FROM _tmp_analytics GROUP BY date_time'
    );

  SELECT UNIX_TIMESTAMP(STR_TO_DATE('2020-04-01' , "%Y-%m-%d"))  INTO _epoch;
  SELECT count(*) FROM entity 
    WHERE ctime <= _start AND ctime >= _epoch AND 
    `status`="active" AND `type`='drumate' INTO _drumates;

  IF @sql IS NOT NULL THEN 
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  SELECT *, _drumates + sum(account) OVER (ORDER BY day) AS 
    total FROM _tmp_results WHERE (ctime <= _end AND ctime >= _start);
  DROP TABLE IF EXISTS _tmp_analytics;
  DROP TABLE IF EXISTS _tmp_results;
END $

DELIMITER ;
