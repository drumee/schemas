
DELIMITER $


DROP PROCEDURE IF EXISTS `analytic_visit`$
CREATE PROCEDURE `analytic_visit`(
  IN _json JSON
)
BEGIN
  DECLARE _cycle json;
  DECLARE _page json;
  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  DECLARE _service VARCHAR(1000);
  DECLARE _i INT(4) DEFAULT 0;
  DECLARE _cnt INT(4) DEFAULT 0;

  SELECT IFNULL(JSON_VALUE(_json, "$.cycle"), 'daterange') INTO _cycle;
  SELECT IFNULL(IFNULL(JSON_QUERY (_json, "$.page"),    JSON_VALUE(_json, "$.page")) , 'all') INTO _page;
  SELECT IFNULL(json_value(_json, "$.service"), 'media.xl') INTO _service;
  CALL yp.parseDateRange(_json, _format, _start, _end);


  DROP TABLE IF EXISTS  _src_page;
  CREATE TEMPORARY TABLE _src_page ( page VARCHAR(50)) ENGINE=MEMORY; 

    WHILE _i < JSON_LENGTH(_page) DO 
        INSERT INTO _src_page SELECT get_json_array(_page, _i) ;
        SELECT _i + 1 INTO _i;
    END WHILE;



  DROP TABLE IF EXISTS  _tmp_analytics;
  CREATE TEMPORARY TABLE _tmp_analytics AS
  SELECT 
    sys_id,
    ctime,
    FROM_UNIXTIME(ctime, _format) AS date_time,
    FROM_UNIXTIME(ctime, '%Y-%m') AS date_mon,
    JSON_VALUE(args, "$.page") AS page,
    JSON_VALUE(headers, "$.referer") referer
  FROM services_log 
    LEFT JOIN _src_page p ON  p.page =  JSON_VALUE(args, "$.page") 
  WHERE 
    (`name` = _service ) AND
    JSON_VALUE(args, "$.page") IS NOT NULL AND 
    JSON_VALUE(args, "$.section") IS NOT NULL AND
    JSON_VALUE(args, "$.area") IS NOT NULL AND
    JSON_VALUE(args, "$.page") =  JSON_VALUE(args, "$.section") AND 
    JSON_VALUE(args, "$.section") =  JSON_VALUE(args, "$.area") AND 
    (ctime <= _end AND ctime >= _start) AND
    CASE WHEN _page  = 'all' THEN  p.page IS NULL  ELSE  p.page IS NOT NULL END  ;

  SELECT COUNT(sys_id) FROM _tmp_analytics  INTO _cnt;

  -- IF _cycle = 'year' THEN
  --   SELECT COUNT(sys_id)  FROM _tmp_analytics GROUP BY  page , date_mon INTO _cnt;
  -- ELSE 
  --   SELECT COUNT(sys_id) FROM _tmp_analytics GROUP BY  page , date_time INTO _cnt;
  -- END  IF;

  IF _cycle = 'year' THEN

        WITH recursive all_dates(dt) as (
            SELECT FROM_UNIXTIME(_start, _format) dt 
                union all 
            SELECT dt + interval 1 month FROM all_dates where dt + interval 1 month <= FROM_UNIXTIME(_end, _format) 
        )
        SELECT  DATE_FORMAT(d.dt ,'%Y-%m-01') date_time, coalesce(t.cnt, 0) cnt ,coalesce(page,'') page
        FROM  all_dates d
        LEFT JOIN ( SELECT COUNT(sys_id) cnt, page , date_mon  as date_time FROM _tmp_analytics GROUP BY  page , date_mon) t ON t.date_time = DATE_FORMAT(d.dt ,'%Y-%m')
        WHERE _cnt > 0
        ORDER by d.dt;

  ELSE 

        WITH recursive all_dates(dt) as (
            SELECT FROM_UNIXTIME(_start, _format) dt 
                union all 
            SELECT dt + interval 1 DAY FROM all_dates where dt + interval 1 DAY <= FROM_UNIXTIME(_end, _format) 
        )
        SELECT  DATE_FORMAT(d.dt ,_format) date_time, coalesce(t.cnt, 0) cnt ,coalesce(page,'') page
        FROM  all_dates d
        LEFT JOIN ( SELECT COUNT(sys_id) cnt, page , date_time FROM _tmp_analytics GROUP BY  page , date_time) t ON t.date_time = DATE_FORMAT(d.dt ,_format)
        WHERE _cnt > 0
        ORDER by d.dt;

  END  IF;


 DROP TABLE IF EXISTS  _src_page;
 DROP TABLE IF EXISTS  _tmp_analytics;

END $




DROP PROCEDURE IF EXISTS `analytic_origin_visit`$
CREATE PROCEDURE `analytic_origin_visit`(
  IN _json JSON
)
BEGIN
  DECLARE _cycle json;
  DECLARE _page json;
  DECLARE _domain json;
  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  DECLARE _service VARCHAR(1000);
  DECLARE _i INT(4) DEFAULT 0;
  DECLARE _cnt INT(4) DEFAULT 0;

  SELECT IFNULL(JSON_VALUE(_json, "$.cycle"), 'daterange') INTO _cycle;
  SELECT IFNULL(IFNULL(JSON_QUERY (_json, "$.page"),    JSON_VALUE(_json, "$.page")) , 'all') INTO _page;
  SELECT IFNULL(IFNULL(JSON_QUERY (_json, "$.domain"),    JSON_VALUE(_json, "$.domain")) , 'all') INTO _domain;
  SELECT IFNULL(json_value(_json, "$.service"), 'media.xl') INTO _service;
  CALL yp.parseDateRange(_json, _format, _start, _end);


  DROP TABLE IF EXISTS  _src_page;
  CREATE TEMPORARY TABLE _src_page ( page VARCHAR(50)) ENGINE=MEMORY; 

    WHILE _i < JSON_LENGTH(_page) DO 
        INSERT INTO _src_page SELECT get_json_array(_page, _i) ;
        SELECT _i + 1 INTO _i;
    END WHILE;

  SELECT  0 INTO _i;
  DROP TABLE IF EXISTS  _src_domain;
  CREATE TEMPORARY TABLE _src_domain ( domain VARCHAR(100)) ENGINE=MEMORY; 

  WHILE _i < JSON_LENGTH(_domain) DO 
      INSERT INTO _src_domain SELECT get_json_array(_domain, _i) ;
      SELECT _i + 1 INTO _i;
  END WHILE;

  DROP TABLE IF EXISTS  _tmp_analytics;
  CREATE TEMPORARY TABLE _tmp_analytics AS
  SELECT 
    sys_id,
    ctime,
    FROM_UNIXTIME(ctime, _format) AS date_time,
    FROM_UNIXTIME(ctime, '%Y-%m') AS date_mon,
    JSON_VALUE(args, "$.page") AS page,
    JSON_VALUE(headers, "$.referer") referer
  FROM services_log 
    LEFT JOIN _src_domain d ON  d.domain = JSON_VALUE(headers, "$.referer")
    LEFT JOIN _src_page p ON  p.page =  JSON_VALUE(args, "$.page") 
  WHERE 
    (`name` = _service ) AND
    JSON_VALUE(headers, "$.referer") IS NOT NULL AND
    JSON_VALUE(args, "$.page") IS NOT NULL AND 
    JSON_VALUE(args, "$.section") IS NOT NULL AND
    JSON_VALUE(args, "$.area") IS NOT NULL AND
    JSON_VALUE(args, "$.page") =  JSON_VALUE(args, "$.section") AND 
    JSON_VALUE(args, "$.section") =  JSON_VALUE(args, "$.area") AND 
    (ctime <= _end AND ctime >= _start) AND
    CASE WHEN _page  = 'all' THEN  p.page IS NULL  ELSE  p.page IS NOT NULL END AND 
    CASE WHEN _domain  = 'all' THEN  d.domain IS NULL  ELSE  d.domain IS NOT NULL END ; 
 
  SELECT COUNT(sys_id) FROM _tmp_analytics  INTO _cnt;

  -- IF _cycle = 'year' THEN
  --   SELECT COUNT(sys_id)  FROM _tmp_analytics GROUP BY  referer , date_mon INTO _cnt;
  -- ELSE 
  --   SELECT COUNT(sys_id) FROM _tmp_analytics GROUP BY  referer , date_time INTO _cnt;
  -- END  IF;



  IF _cycle = 'year' THEN

        WITH recursive all_dates(dt) as (
            SELECT FROM_UNIXTIME(_start, _format) dt 
                union all 
            SELECT dt + interval 1 month FROM all_dates where dt + interval 1 month <= FROM_UNIXTIME(_end, _format) 
        )
        SELECT  DATE_FORMAT(d.dt ,'%Y-%m-01') date_time, coalesce(t.cnt, 0) cnt ,coalesce(referer,'') referer
        FROM  all_dates d
        LEFT JOIN (SELECT COUNT(sys_id) cnt, referer , date_mon as date_time FROM _tmp_analytics GROUP BY  referer , date_mon) t ON t.date_time = DATE_FORMAT(d.dt ,'%Y-%m')
        WHERE _cnt > 0
        ORDER by d.dt;

  ELSE 

        WITH recursive all_dates(dt) as (
            SELECT FROM_UNIXTIME(_start, _format) dt 
                union all 
            SELECT dt + interval 1 DAY FROM all_dates where dt + interval 1 DAY <= FROM_UNIXTIME(_end, _format) 
        )
        SELECT  DATE_FORMAT(d.dt ,_format) date_time, coalesce(t.cnt, 0) cnt ,coalesce(referer,'') referer
        FROM  all_dates d
        LEFT JOIN (SELECT COUNT(sys_id) cnt, referer , date_time FROM _tmp_analytics GROUP BY  referer , date_time) t ON t.date_time = DATE_FORMAT(d.dt ,_format)
        WHERE _cnt > 0
        ORDER by d.dt;

  END  IF;




 DROP TABLE IF EXISTS  _src_page;
 DROP TABLE IF EXISTS  _tmp_analytics;
 DROP TABLE IF EXISTS  _src_domain;

END $




DROP PROCEDURE IF EXISTS `analytic_tracking_button`$
CREATE PROCEDURE `analytic_tracking_button`(
  IN _json JSON
)
BEGIN
  DECLARE _cycle json;
  DECLARE _page json;
  DECLARE _section json;
  DECLARE _area json;

  DECLARE _format VARCHAR(120);
  DECLARE _start INT(11) unsigned;
  DECLARE _end INT(11) unsigned;
  DECLARE _service VARCHAR(1000);
  DECLARE _i INT(4) DEFAULT 0;
  DECLARE _cnt INT(4) DEFAULT 0;

  SELECT IFNULL(JSON_VALUE(_json, "$.cycle"), 'daterange') INTO _cycle;
  SELECT IFNULL(IFNULL(JSON_QUERY (_json, "$.page"),    JSON_VALUE(_json, "$.page")) , 'all') INTO _page;
  SELECT IFNULL(IFNULL(JSON_QUERY (_json, "$.section"),    JSON_VALUE(_json, "$.section")) , 'all') INTO _section;
  SELECT IFNULL(IFNULL(JSON_QUERY (_json, "$.area"),    JSON_VALUE(_json, "$.area")) , 'all') INTO _area;

  SELECT IFNULL(json_value(_json, "$.service"), 'media.xl') INTO _service;
  CALL yp.parseDateRange(_json, _format, _start, _end);


  DROP TABLE IF EXISTS  _src_page;
  CREATE TEMPORARY TABLE _src_page ( page VARCHAR(50)) ENGINE=MEMORY; 

    WHILE _i < JSON_LENGTH(_page) DO 
        INSERT INTO _src_page SELECT get_json_array(_page, _i) ;
        SELECT _i + 1 INTO _i;
    END WHILE;

  SELECT  0 INTO _i;
  DROP TABLE IF EXISTS  _src_section;
  CREATE TEMPORARY TABLE _src_section ( section VARCHAR(100)) ENGINE=MEMORY; 

  WHILE _i < JSON_LENGTH(_section) DO 
      INSERT INTO _src_section SELECT get_json_array(_section, _i) ;
      SELECT _i + 1 INTO _i;
  END WHILE;


 SELECT  0 INTO _i;
  DROP TABLE IF EXISTS  _src_area;
  CREATE TEMPORARY TABLE _src_area ( area VARCHAR(100)) ENGINE=MEMORY; 

  WHILE _i < JSON_LENGTH(_area) DO 
      INSERT INTO _src_area SELECT get_json_array(_area, _i) ;
      SELECT _i + 1 INTO _i;
  END WHILE;

  DROP TABLE IF EXISTS  _tmp_analytics;
  CREATE TEMPORARY TABLE _tmp_analytics AS
  SELECT 
    sys_id,
    ctime,
    FROM_UNIXTIME(ctime, _format) AS date_time,
    FROM_UNIXTIME(ctime, '%Y-%m') AS date_mon,
    JSON_VALUE(args, "$.area") AS area
  FROM services_log 
    LEFT JOIN _src_page p ON  p.page =  JSON_VALUE(args, "$.page") 
    LEFT JOIN _src_section s ON  s.section = JSON_VALUE(args, "$.section")
    LEFT JOIN _src_area a ON  a.area = JSON_VALUE(args, "$.area")
  WHERE 
    (`name` = _service ) AND
    JSON_VALUE(args, "$.page") IS NOT NULL AND 
    JSON_VALUE(args, "$.section") IS NOT NULL AND
    JSON_VALUE(args, "$.area") IS NOT NULL AND
    (ctime <= _end AND ctime >= _start) AND
    CASE WHEN _page  = 'all' THEN  p.page IS NULL  ELSE  p.page IS NOT NULL END AND 
    CASE WHEN _section  = 'all' THEN  s.section IS NULL  ELSE s.section IS NOT NULL END AND
    CASE WHEN _area  = 'all' THEN  a.area IS NULL  ELSE a.area IS NOT NULL END ; 

   SELECT COUNT(sys_id) FROM _tmp_analytics  INTO _cnt;

  -- IF _cycle = 'year' THEN
  --   SELECT COUNT(sys_id)  FROM _tmp_analytics GROUP BY  area , date_mon INTO _cnt;
  -- ELSE 
  --   SELECT COUNT(sys_id) FROM _tmp_analytics GROUP BY  area , date_time INTO _cnt;
  -- END  IF;

  IF _cycle = 'year' THEN

        WITH recursive all_dates(dt) as (
            SELECT FROM_UNIXTIME(_start, _format) dt 
                union all 
            SELECT dt + interval 1 month FROM all_dates where dt + interval 1 month <= FROM_UNIXTIME(_end, _format) 
        )
        SELECT  DATE_FORMAT(d.dt ,'%Y-%m-01') date_time, coalesce(t.cnt, 0) cnt ,coalesce(area,'') area
        FROM  all_dates d
        LEFT JOIN (SELECT COUNT(sys_id) cnt, area , date_mon  as date_time FROM _tmp_analytics GROUP BY  area , date_mon) t ON t.date_time = DATE_FORMAT(d.dt ,'%Y-%m')
        WHERE _cnt > 0
        ORDER by d.dt;

  ELSE 

        WITH recursive all_dates(dt) as (
            SELECT FROM_UNIXTIME(_start, _format) dt 
                union all 
            SELECT dt + interval 1 DAY FROM all_dates where dt + interval 1 DAY <= FROM_UNIXTIME(_end, _format) 
        )
        SELECT  DATE_FORMAT(d.dt ,_format) date_time, coalesce(t.cnt, 0) cnt ,coalesce(area,'') area
        FROM  all_dates d
        LEFT JOIN (SELECT COUNT(sys_id) cnt, area , date_time FROM _tmp_analytics GROUP BY  area , date_time) t ON t.date_time = DATE_FORMAT(d.dt ,_format)
        WHERE _cnt > 0
        ORDER by d.dt;

  END  IF;

 DROP TABLE IF EXISTS  _src_page;
 DROP TABLE IF EXISTS  _tmp_analytics;
 DROP TABLE IF EXISTS  _src_area;
 DROP TABLE IF EXISTS  _src_section;

END $


DELIMITER ;


/*
SELECT JSON_OBJECT ('cycle','daterange', 'page' ,'["home","privacy"]','domrrain' ,'["home","privacy"]','start' , '2022-03-02', 'end' , '2022-06-01' ,'time_format', '%Y-%m-%d') INTO @json;
CALL analytic_visit(@json);
CALL analytic_origin_visit( @json);
CALL analytic_tracking_button( @json);

SELECT JSON_OBJECT ('cycle','daterange', 'page' ,'all','domrrain' ,'["home","privacy"]','start' , '2022-03-02', 'end' , '2022-06-01' ,'time_format', '%Y-%m-%d') INTO @json;
CALL analytic_visit(@json);
*/