
DELIMITER $


DROP PROCEDURE IF EXISTS `analytic_hub_usage`$
/*CREATE PROCEDURE `analytic_hub_usage`(
  IN _json JSON
)
BEGIN
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE _db_name VARCHAR(56);

  DECLARE dbcursor CURSOR FOR SELECT e.db_name 
    FROM yp.drumate d INNER JOIN yp.entity e USING(id) 
    WHERE JSON_VALUE(profile, "$.profile_type")='hub';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

    DROP TABLE IF EXISTS __tmp_analytics;
  CREATE TEMPORARY TABLE __tmp_analytics AS SELECT 
    id, 
    filesize,
    upload_time AS ctime,
    category
  FROM media where 1=2;


  OPEN dbcursor;
    STARTLOOP: LOOP
    FETCH dbcursor INTO _db_name;
      SET @s = CONCAT("INSERT INTO __tmp_analytics SELECT ", 
      "id, 
      filesize, 
      upload_time AS ctime,
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
  

  SELECT FROM_UNIXTIME(ctime, "%y-%m-%d") day, 
  sum(filesize) OVER (ORDER BY day) AS size 
  FROM __tmp_analytics GROUP BY day;
  DROP TABLE IF EXISTS __tmp_analytics;
END $
*/

DELIMITER ;
