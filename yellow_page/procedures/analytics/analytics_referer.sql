
DELIMITER $


DROP PROCEDURE IF EXISTS `analytics_referer`$
CREATE PROCEDURE `analytics_referer`(
  IN _json JSON
)
BEGIN
  DECLARE _format VARCHAR(120);
  DECLARE _probe_id VARCHAR(16);
  DECLARE _domain VARCHAR(1000);
  DECLARE _domains json;
  DECLARE _service VARCHAR(1000);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  DECLARE _i INT DEFAULT 0;

  DROP TABLE IF EXISTS _tmp_analytics;

  CALL yp.parseDateRange(_json, _format, _start, _end);

  SELECT IFNULL(json_value(_json, "$.service"), 'media.xl') INTO _service;
  SELECT json_value(_json, "$.probeId") INTO _probe_id;


  CREATE TEMPORARY TABLE _tmp_analytics AS SELECT 
    sys_id,
    ctime,
    FROM_UNIXTIME(ctime, _format) AS date_time,
    JSON_VALUE(args, "$.nid") AS probe_id,
    IFNULL(
      JSON_VALUE(args, "$.referer"), 
      IFNULL(
        REGEXP_REPLACE(
          JSON_VALUE(headers, "$.referer"), 
          "^http.+://|/.+$|/$|\:443", ""
        ), 
        JSON_VALUE(headers, "$.referer")
      )
    ) AS referer
    FROM services_log WHERE (`name` = _service OR `name` = '') AND
      (ctime <= _end AND ctime >= _start);

  ALTER TABLE _tmp_analytics ADD PRIMARY KEY (`sys_id`); 

  SELECT JSON_EXTRACT(_json, "$.domains") INTO _domains;

  SET @sql = "UPDATE _tmp_analytics SET referer='other' WHERE 
  referer IS NULL OR referer NOT IN (";

  WHILE _i < JSON_LENGTH(_domains) DO
    SELECT read_json_array(_domains, _i) INTO @_dom;
    SET @_regexp = CONCAT("^.*\.", @_dom ,"$");
    -- SELECT @_regexp, @_dom;
    UPDATE _tmp_analytics SET referer = REGEXP_REPLACE(referer, @_regexp, @_dom);
    SELECT _i + 1 INTO _i;
    SELECT CONCAT(@sql, QUOTE(@_dom), ",") INTO @sql;
  END WHILE;
  SELECT REGEXP_REPLACE(@sql, ",$", ")") INTO @sql;

  IF @sql IS NOT NULL THEN 
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;


  SELECT
    GROUP_CONCAT(DISTINCT
      CONCAT(
        "SUM(IF(referer=", QUOTE(referer), ", 1, 0)) AS `", referer, "` "
      )
    ) INTO @sql
  FROM _tmp_analytics;


  SET @sql = CONCAT(
    'SELECT date_time, ', 
    'CAST(FROM_UNIXTIME(ctime, "%H") AS INT) hour, ',
    'FROM_UNIXTIME(ctime, "%Y-%m-%d") AS day, ',
    @sql, 
    'FROM _tmp_analytics GROUP BY date_time'
    );

  IF @sql IS NOT NULL THEN 
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  DROP TABLE IF EXISTS _tmp_analytics;
END $

DELIMITER ;
