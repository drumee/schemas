
DELIMITER $


DROP PROCEDURE IF EXISTS `analytic_hub_usage`$
CREATE PROCEDURE `analytic_hub_usage`(
  IN _json JSON
)
BEGIN
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE _db_name VARCHAR(56);

  DECLARE dbcursor CURSOR FOR SELECT e.db_name 
    FROM yp.drumate d INNER JOIN yp.entity e USING(id) 
    WHERE JSON_VALUE(profile, "$.profile_type")='hub' AND `status`="active";

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

  DROP TABLE IF EXISTS __tmp_analytics;
  CREATE TEMPORARY TABLE __tmp_analytics(
    `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
    `filesize` bigint(20) unsigned DEFAULT 0,
    `ctime` int(11) unsigned NOT NULL DEFAULT 0,
    `category` varchar(16) NOT NULL DEFAULT 'other',
    PRIMARY KEY (`sys_id`)
  );


  OPEN dbcursor;
    STARTLOOP: LOOP
    FETCH dbcursor INTO _db_name;
      SET @s = CONCAT("INSERT INTO __tmp_analytics SELECT NULL, ", 
      "id, 
      filesize, 
      upload_time,
      category FROM ", 
      _db_name, 
      ".media WHERE extension !='root' AND status IN('active', 'locked')");
    -- SELECT @s;
    IF _finished = 1 THEN 
      LEAVE STARTLOOP;
    END IF;    
 
    IF @s IS NOT NULL THEN 
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;
    END LOOP STARTLOOP;
  CLOSE dbcursor;
  

  DROP TABLE IF EXISTS _tmp_results;
  CREATE TEMPORARY TABLE _tmp_results AS SELECT 
    FROM_UNIXTIME(ctime, "%y-%m-%d") day, 
    round(sum(filesize)/(1024*1024)) AS size 
  FROM __tmp_analytics GROUP BY day;

  IF(JSON_VALUE(_json, "$.serie") = 'history') THEN 
    SELECT *, sum(size) OVER (ORDER BY day) AS 
      total FROM _tmp_results GROUP BY day ASC;
  ELSE
    SELECT *, size as total FROM _tmp_results GROUP BY day ASC;
  END IF;
  DROP TABLE IF EXISTS _tmp_results;
  DROP TABLE IF EXISTS __tmp_analytics;
END $

DELIMITER ;
