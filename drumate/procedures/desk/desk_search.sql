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
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _pattern TEXT;
  DECLARE _page INTEGER DEFAULT 1;
  DECLARE _idx_time INT(11) UNSIGNED DEFAULT 0;
  DECLARE _ts INT(11) UNSIGNED;
  
  SELECT IFNULL(JSON_VALUE(_args, "$.sort_by"), 'mtime') INTO _sort_by;
  SELECT IFNULL(JSON_VALUE(_args, "$.order"), 'desc') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pagelength"), 45) INTO @rows_per_page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pattern"), '.+') INTO _pattern;

  SELECT max(timestamp) FROM media_index INTO _idx_time;
  SELECT UNIX_TIMESTAMP() INTO _ts;

  IF _idx_time IS NULL  THEN
    CALL desk_build_index(JSON_OBJECT());
  ELSE
    SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _uid;
    BEGIN
      DECLARE _finished INTEGER DEFAULT 0;
      DECLARE _src JSON;
      DECLARE _dest JSON;
      DECLARE _event VARCHAR(20) DEFAULT 'desc';
      DECLARE _last_ts INT(11) UNSIGNED;
      DECLARE dbcursor CURSOR FOR SELECT event, src, dest 
        FROM yp.mfs_changelog WHERE uid=_uid AND timestamp > _idx_time;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
      OPEN dbcursor;
        STARTLOOP: LOOP
          FETCH dbcursor INTO _event, _src, _dest;
          IF _finished = 1 THEN 
            LEAVE STARTLOOP;
          END IF;

          IF _event IN ('media.new', 'media.replace', 'media.make_dir') THEN 
            REPLACE INTO media_index SELECT
              JSON_VALUE(_src, "$.hub_id"),
              JSON_VALUE(_src, "$.home_id"),
              COALESCE(JSON_VALUE(_src, "$.actual_home_id"), JSON_VALUE(_src, "$.home_id")),
              JSON_VALUE(_src, "$.pid"),
              JSON_VALUE(_src, "$.nid"),
              JSON_VALUE(_src, "$.md5Hash"),
              JSON_VALUE(_src, "$.area"),
              JSON_VALUE(_src, "$.filetype"),
              JSON_VALUE(_src, "$.ext"),
              JSON_VALUE(_src, "$.status"),
              JSON_VALUE(_src, "$.isalink"),
              JSON_VALUE(_src, "$.privilege"),
              JSON_VALUE(_src, "$.filesize"),
              JSON_VALUE(_src, "$.filename"),
              JSON_VALUE(_src, "$.filepath"),
              JSON_VALUE(_src, "$.ownpath"),
              JSON_VALUE(_src, "$.mtime"),
              JSON_VALUE(_src, "$.ctime"),
              _ts;

          ELSEIF _event IN ('media.move', 'media.relocate', 'media.rename', 'media.copy') THEN 
            DELETE FROM media_index WHERE hub_id=JSON_VALUE(_src, "$.hub_id") AND nid=JSON_VALUE(_src, "$.nid");

            REPLACE INTO media_index SELECT
              JSON_VALUE(_dest, "$.hub_id"),
              JSON_VALUE(_dest, "$.home_id"),
              COALESCE(JSON_VALUE(_dest, "$.actual_home_id"), JSON_VALUE(_src, "$.home_id")),
              JSON_VALUE(_dest, "$.pid"),
              JSON_VALUE(_dest, "$.nid"),
              JSON_VALUE(_dest, "$.md5Hash"),
              JSON_VALUE(_dest, "$.area"),
              JSON_VALUE(_dest, "$.filetype"),
              JSON_VALUE(_dest, "$.ext"),
              JSON_VALUE(_dest, "$.status"),
              JSON_VALUE(_dest, "$.isalink"),
              JSON_VALUE(_dest, "$.privilege"),
              JSON_VALUE(_dest, "$.filesize"),
              JSON_VALUE(_dest, "$.filename"),
              JSON_VALUE(_dest, "$.filepath"),
              JSON_VALUE(_dest, "$.ownpath"),
              JSON_VALUE(_dest, "$.mtime"),
              JSON_VALUE(_dest, "$.ctime"),
              _ts;

          ELSEIF _event IN ('media.remove') THEN 
            DELETE FROM media_index WHERE hub_id=JSON_VALUE(_src, "$.hub_id") AND nid=JSON_VALUE(_src, "$.nid");
            SELECT timestamp FROM media_index ORDER BY timestamp DESC LIMIT 1 INTO _last_ts;
            UPDATE media_index SET timestamp = _ts WHERE timestamp=_last_ts;
          END IF;

        END LOOP STARTLOOP;
      CLOSE dbcursor;    
    END;
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


