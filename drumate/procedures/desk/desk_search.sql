DELIMITER $

DROP PROCEDURE IF EXISTS `desk_search`$
CREATE PROCEDURE `desk_search`(
  IN _args JSON
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _sort_by VARCHAR(20) DEFAULT 'mtime';
  DECLARE _order VARCHAR(20) DEFAULT 'desc';
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _pattern TEXT;
  DECLARE _page INTEGER DEFAULT 1;
  DECLARE _idx_time BIGINT UNSIGNED DEFAULT 0;
  DECLARE _ts BIGINT UNSIGNED;
  DECLARE _last_change BIGINT UNSIGNED;

  -- Default to relevance: this proc only serves the desk search bar, where the
  -- closest name match is what the user is looking for. An explicit sort_by
  -- ('mtime' | 'name' | 'size') still behaves exactly as before.
  SELECT IFNULL(JSON_VALUE(_args, "$.sort_by"), 'relevance') INTO _sort_by;
  SELECT IFNULL(JSON_VALUE(_args, "$.order"), 'desc') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pagelength"), 45) INTO @rows_per_page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pattern"), '') INTO _pattern;

  -- Get current user
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _uid;

  SELECT max(timestamp) FROM media_index INTO _idx_time;
  SELECT UNIX_TIMESTAMP() INTO _ts;

  -- Create temp table of accessible hubs
  DROP TEMPORARY TABLE IF EXISTS _user_accessible_hubs;
  CREATE TEMPORARY TABLE _user_accessible_hubs (
    hub_id VARCHAR(16) CHARACTER SET ascii PRIMARY KEY
  );
  
  -- User owns these hubs
  INSERT INTO _user_accessible_hubs (hub_id)
  SELECT id FROM yp.hub WHERE owner_id = _uid;
  
  -- Permission table is in user database
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  SELECT id from media where category='hub';
  
  -- User's personal space
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  VALUES (_uid);

  SELECT max(timestamp) FROM yp.mfs_changelog WHERE hub_id IN(SELECT hub_id FROM _user_accessible_hubs)
    INTO _last_change;

  IF _idx_time IS NULL OR _idx_time<=_last_change THEN
    CALL desk_build_index(JSON_OBJECT());
  ELSE
    START TRANSACTION;

    BEGIN
      DECLARE _finished INTEGER DEFAULT 0;
      DECLARE _src JSON;
      DECLARE _dest JSON;
      DECLARE _event VARCHAR(20);
      DECLARE _hub_id VARCHAR(16);
      DECLARE _area VARCHAR(20);

      DECLARE dbcursor CURSOR FOR 
        SELECT event, src, dest 
        FROM yp.mfs_changelog 
        WHERE uid=_uid 
          AND timestamp > _idx_time
        ORDER BY timestamp ASC;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

      OPEN dbcursor;

        STARTLOOP: LOOP
          FETCH dbcursor INTO _event, _src, _dest;
          IF _finished = 1 THEN 
            LEAVE STARTLOOP;
          END IF;

          -- Get hub_id to lookup area if missing
          SELECT JSON_VALUE(_src, "$.hub_id") INTO _hub_id;
          SELECT JSON_VALUE(_src, "$.area") INTO _area;

          -- If area is NULL, get it from hub
          IF _area IS NULL OR _area = '' THEN
            SELECT area FROM yp.entity WHERE id = _hub_id INTO _area;
          END IF;

          IF _event IN ('media.new', 'media.replace', 'media.make_dir') THEN 
            REPLACE INTO media_index SELECT
              _hub_id,
              JSON_VALUE(_src, "$.home_id"),
              COALESCE(JSON_VALUE(_src, "$.actual_home_id"), JSON_VALUE(_src, "$.home_id")),
              JSON_VALUE(_src, "$.pid"),
              JSON_VALUE(_src, "$.nid"),
              JSON_VALUE(_src, "$.md5Hash"),
              _area,
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
            DELETE FROM media_index 
            WHERE hub_id=JSON_VALUE(_src, "$.hub_id") 
              AND nid=JSON_VALUE(_src, "$.nid");

            -- Get area from dest
            SELECT JSON_VALUE(_dest, "$.hub_id") INTO _hub_id;
            SELECT JSON_VALUE(_dest, "$.area") INTO _area;

            IF _area IS NULL OR _area = '' THEN
              SELECT area FROM yp.entity WHERE id = _hub_id INTO _area;
            END IF;

            REPLACE INTO media_index SELECT
              _hub_id,
              JSON_VALUE(_dest, "$.home_id"),
              COALESCE(JSON_VALUE(_dest, "$.actual_home_id"), JSON_VALUE(_src, "$.home_id")),
              JSON_VALUE(_dest, "$.pid"),
              JSON_VALUE(_dest, "$.nid"),
              JSON_VALUE(_dest, "$.md5Hash"),
              _area,
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
            DELETE FROM media_index 
            WHERE hub_id=JSON_VALUE(_src, "$.hub_id") 
              AND nid=JSON_VALUE(_src, "$.nid");
          END IF;
        END LOOP STARTLOOP;
      CLOSE dbcursor;    
    END;

    COMMIT;
  END IF;


  CALL yp.pageToLimits(_page, _offset, _range); 

  -- Match the typed keyword against the node's OWN name only (m.filename),
  -- never its ancestor path (m.filepath) — otherwise every node living under a
  -- folder/workspace whose path contains the keyword would show up as an
  -- unrelated result. Case-insensitive substring match (utf8mb4_general_ci).
  SELECT
    m.*,
    v.fqdn AS vhost,
    m.pid AS parent_id
  FROM media_index m
  LEFT JOIN yp.vhost v ON m.hub_id = v.id
  WHERE m.status = 'active' AND m.filename IS NOT NULL
    AND m.filename LIKE CONCAT('%', _pattern, '%')
  ORDER BY
    -- Relevance (the default): closest name match first.
    --   0 the name IS the keyword, 1 the name starts with it, 2 the keyword
    --   starts a word inside the name (separators _ - . are read as spaces),
    --   3 it appears anywhere else.
    -- Ties break on the shorter (so more specific) name, then most recent.
    -- Every term is inert unless sort_by = 'relevance', so the explicit
    -- mtime/name/size orders below keep their existing behaviour.
    CASE WHEN _sort_by = 'relevance' THEN
      CASE
        WHEN m.filename = _pattern THEN 0
        WHEN m.filename LIKE CONCAT(_pattern, '%') THEN 1
        WHEN REPLACE(REPLACE(REPLACE(m.filename, '_', ' '), '-', ' '), '.', ' ')
             LIKE CONCAT('% ', _pattern, '%') THEN 2
        ELSE 3
      END
    END ASC,
    CASE WHEN _sort_by = 'relevance' THEN CHAR_LENGTH(m.filename) END ASC,
    CASE WHEN _sort_by = 'relevance' THEN m.mtime END DESC,
    CASE WHEN _sort_by = 'mtime' AND _order = 'desc' THEN m.mtime END DESC,
    CASE WHEN _sort_by = 'mtime' AND _order = 'asc' THEN m.mtime END ASC,
    CASE WHEN _sort_by = 'name' AND _order = 'asc' THEN m.filename END ASC,
    CASE WHEN _sort_by = 'name' AND _order = 'desc' THEN m.filename END DESC,
    CASE WHEN _sort_by = 'size' AND _order = 'desc' THEN m.filesize END DESC,
    CASE WHEN _sort_by = 'size' AND _order = 'asc' THEN m.filesize END ASC
  LIMIT _offset, _range;
  DROP TEMPORARY TABLE IF EXISTS _user_accessible_hubs;
END $

DELIMITER ;


