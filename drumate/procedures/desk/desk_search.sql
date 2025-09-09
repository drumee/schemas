DELIMITER $

DROP PROCEDURE IF EXISTS `desk_search`$
CREATE PROCEDURE `desk_search`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _sort_by VARCHAR(20) DEFAULT 'name';
  DECLARE _order VARCHAR(20) DEFAULT 'desc';
  DECLARE _pattern TEXT;
  DECLARE _page INTEGER DEFAULT 1;
  DECLARE _idx_time INT(11) UNSIGNED DEFAULT 0;
  DECLARE _ctime INT(11) UNSIGNED;
  
  SELECT IFNULL(JSON_VALUE(_args, "$.sort_by"), 'mtime') INTO _sort_by;
  SELECT IFNULL(JSON_VALUE(_args, "$.order"), 'desc') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pagelength"), 45) INTO @rows_per_page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pattern"), '.+') INTO _pattern;

  SELECT IFNULL(max(mtime), 0) FROM media_index INTO _idx_time;
  SELECT max(upload_time) FROM media INTO _ctime;
  IF(_ctime > _idx_time) THEN
    CALL desk_build_index(JSON_OBJECT());
  END IF;
  CALL yp.pageToLimits(_page, _offset, _range); 
  SELECT 
    *, 
    fqdn vhost,
    pid parent_id 
  FROM media_index m
    LEFT JOIN yp.vhost v ON m.hub_id= v.id
    WHERE filename REGEXP _pattern ORDER BY mtime DESC LIMIT _offset, _range;
END $


DELIMITER ;


