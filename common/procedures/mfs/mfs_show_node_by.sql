DELIMITER $

-- ==============================================================
-- mfs_show_node_by
-- List files + directories under directory identified by node_id
-- OPTIMIZED: Uses mfs_changelog + mfs_ack instead of is_new() function
-- ==============================================================

DROP PROCEDURE IF EXISTS `mfs_show_node_by_next`$
DROP PROCEDURE IF EXISTS `mfs_show_node_by`$
CREATE PROCEDURE `mfs_show_node_by`(
  IN _node_id VARCHAR(16) CHARACTER SET ascii,
  IN _uid     VARCHAR(16) CHARACTER SET ascii,
  IN _params  JSON
)
BEGIN

  DECLARE _sort_by      VARCHAR(20);
  DECLARE _order        VARCHAR(20);
  DECLARE _page         TINYINT(4);
  DECLARE _type         VARCHAR(10);

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _ftype VARCHAR(255);

  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(400);

  DECLARE _tempid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _heritage_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _category VARCHAR(16);
  DECLARE _area VARCHAR(30);
  DECLARE _hub_area VARCHAR(30);
  DECLARE _flag_expiry VARCHAR(30);
  DECLARE _lvl INT;
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _username VARCHAR(100);
  DECLARE _org VARCHAR(500);
  DECLARE _ts INT(11);
  DECLARE _expiry_time INT(11);
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_name VARCHAR(5000);
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;

  -- Extract params from JSON with defaults
  SELECT IFNULL(JSON_VALUE(_params, '$.sort_by'), 'rank') INTO _sort_by;
  SELECT IFNULL(JSON_VALUE(_params, '$.order'),   'asc')  INTO _order;
  SELECT IFNULL(JSON_VALUE(_params, '$.page'),    1)      INTO _page;
  SELECT IFNULL(JSON_VALUE(_params, '$.type'),    'all')  INTO _type;

  SELECT UNIX_TIMESTAMP() INTO _ts;

  -- Force user defined var to the same collation
  SELECT _utf8mb4'' COLLATE utf8mb4_general_ci INTO @parent_path;
  SELECT _utf8mb4'' COLLATE utf8mb4_general_ci INTO @hub_name;

  CALL pageToLimits(_page, _offset, _range);
  SELECT database() INTO _src_db_name;
  SELECT id FROM media WHERE parent_id='0' INTO _home_id;

  SELECT h.id, e.area
    FROM yp.hub h INNER JOIN yp.entity e ON e.id = h.id
    WHERE db_name=_src_db_name INTO _root_hub_id, _hub_area;
  SELECT '' INTO _hub_name;

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
    SELECT '' INTO @hub_name;
    IF _user_db_name IS NOT NULL THEN
      SET @s = CONCAT("
          SELECT user_filename, parent_path
          FROM  ", _user_db_name, ".media m
          WHERE m.id='", _root_hub_id, "' INTO @hub_name, @parent_path"
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      IF @hub_name IS NOT NULL AND @hub_name <> '' THEN
        SELECT CONCAT(@parent_path, '/', @hub_name) INTO _hub_name;
      END IF;

      -- Get user's last_read_id from mfs_ack table
      SET @s = CONCAT("
          SELECT IFNULL(last_read_id, 0)
          FROM ", _user_db_name, ".mfs_ack
          WHERE user_id = '", _uid, "' INTO @last_read_id"
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT IFNULL(@last_read_id, 0) INTO _last_read_id;
    END IF;
  END IF;

  SELECT yp.get_sysconf('guest_id') INTO @guest_id;

  IF _node_id IS NULL OR _node_id='0' THEN
    SELECT _home_id INTO _node_id;
  END IF;

  IF _node_id REGEXP "^/.+" THEN
    SELECT id FROM media WHERE file_path = clean_path(_node_id) INTO _node_id;
  END IF;

  -- Create temp table for latest changelog events per node
  DROP TABLE IF EXISTS _temp_latest_events;
  CREATE TEMPORARY TABLE _temp_latest_events (
    nid VARCHAR(16) CHARACTER SET ascii PRIMARY KEY,
    latest_event_id INT(11) UNSIGNED
  );

  -- Populate with latest changelog event per node.
  -- `nid` is a VIRTUAL generated column on yp.mfs_changelog
  -- (= COALESCE(JSON_VALUE(src,'$.nid'), JSON_VALUE(dest,'$.nid'))) indexed by
  -- idx_nid(nid, id). Referencing it directly lets this GROUP BY + MAX(id) run as
  -- a covering index scan instead of a full table scan with per-row JSON parsing.
  -- (Requires the idx_nid migration applied to yp.mfs_changelog — shipped first.)
  INSERT INTO _temp_latest_events (nid, latest_event_id)
  SELECT nid, MAX(id) AS latest_event_id
  FROM yp.mfs_changelog
  WHERE nid IS NOT NULL
    AND CHAR_LENGTH(nid) <= 16
    -- new_file only flags events newer than the caller's last read, so rows with
    -- id <= _last_read_id can never set new_file=1 (see the new_file CASE below).
    -- Excluding them keeps this an incremental scan instead of aggregating the
    -- entire global changelog on every listing.
    AND id > _last_read_id
  GROUP BY nid;

  DROP TABLE IF EXISTS _temp_show_node;
  CREATE TEMPORARY TABLE _temp_show_node AS
  SELECT
    m.id AS nid,
    m.parent_id AS pid,
    m.parent_id AS parent_id,
    CONCAT(_hub_name, m.file_path) AS filepath,
    IF(m.category = 'hub', '/', m.file_path) AS ownpath,
    me.id AS holder_id,
    _home_id AS home_id,
    null capability,
    _src_db_name AS src_db_name,
    he.db_name hub_db_name,
    COALESCE(he.accessibility, me.accessibility) AS accessibility,
    COALESCE(he.id, hh.owner_id) AS owner_id,
    COALESCE(he.id, me.id) AS hub_id,
    COALESCE(he.status, m.status) AS status,
    m.user_filename AS filename,
    m.filesize AS filesize,
    COALESCE(vv.fqdn, v.fqdn) AS vhost,
    he.area AS area,
    m.caption,
    m.extension AS ext,
    m.category AS ftype,
    m.mimetype mimetype,
    m.metadata,
    m.download_count AS view_count,
    m.geometry,
    m.upload_time AS ctime,
    m.publish_time AS mtime,
    IF(
      m.owner_id = _uid,
      0,
      IF(
        IFNULL(evt.latest_event_id, 0) > _last_read_id,
        1,  -- Event exists and is newer than last read
        0   -- No event or already read
      )
    ) AS new_file,
    isalink,
    _page AS page,
    m.rank,
    IF(m.category = 'hub', null, user_permission(_uid, m.id)) privilege,
    IF(m.category = 'hub', null, user_expiry(_uid, m.id)) expiry_time
  FROM media m
    INNER JOIN yp.entity me  ON me.db_name=database()
    LEFT JOIN  yp.vhost v    ON v.id=me.id
    LEFT JOIN  yp.vhost vv   ON vv.id=m.id
    LEFT JOIN  yp.entity he  ON m.id=he.id AND m.category='hub'
    LEFT JOIN  yp.hub hh     ON m.id=hh.id AND m.category='hub'
    LEFT JOIN  _temp_latest_events evt ON m.id=evt.nid
  WHERE m.parent_id = _node_id
    AND m.file_path NOT REGEXP '^/__(chat|trash|upload)__'
    AND m.`status` NOT IN ('hidden', 'deleted')
    AND (
      _type = 'all'
      OR (_type = 'node' AND m.category IN ('folder', 'hub'))
      OR (_type = 'hub'  AND m.category = 'hub')
      OR (_type = 'file' AND m.category NOT IN ('folder', 'hub', 'root'))
      OR (_type = 'docs'  AND m.category = 'document' AND m.extension != 'pdf')
      OR (_type = 'pdf'   AND m.category = 'document' AND m.extension = 'pdf')
      OR (_type = 'image' AND m.category = 'image')
      OR (_type = 'other' AND m.category NOT IN ('folder', 'hub', 'root', 'document', 'image'))
    );

  ALTER TABLE _temp_show_node ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;
  ALTER TABLE _temp_show_node ADD flag_expiry VARCHAR(30) DEFAULT 'na';

  SELECT sys_id, IF(ftype = 'hub', hub_db_name, null), IF(ftype = 'hub', nid, null), area
    FROM _temp_show_node WHERE sys_id > 0 AND (hub_db_name IS NOT NULL) ORDER BY sys_id ASC LIMIT 1
    INTO _sys_id, _db, _nid, _area;

  WHILE _sys_id <> 0 DO

    SET @perm = 0;
    SET @resexpiry = NULL;
    SET @s = CONCAT("SELECT ",
      _db, ".user_permission (?, ?) INTO @perm"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;

    SET @resexpiry = null;
    SET @s = CONCAT("SELECT ",
      _db, ".user_expiry (?, ?) INTO @resexpiry"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;

    SELECT 'na' INTO _flag_expiry;

    IF _area = 'share' THEN
      SET @expiry_time = NULL;
      SET @s = CONCAT("
        SELECT p.expiry_time
        FROM  ", _db, ".permission p
        INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
        INNER JOIN yp.dmz_user u  ON p.entity_id = u.id
        INNER JOIN yp.entity e    ON e.id = t.hub_id AND e.home_id = t.node_id
        WHERE e.db_name='", _db, "' AND u.id = @guest_id INTO @expiry_time"
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT
        CASE
          WHEN IFNULL(@expiry_time, 0) = 0 THEN 'infinity'
          WHEN (@expiry_time - _ts) <= 0    THEN 'expired'
          ELSE 'active'
        END INTO _flag_expiry;
    END IF;

    UPDATE _temp_show_node s
      SET privilege = @perm, expiry_time = @resexpiry, flag_expiry = _flag_expiry
      WHERE sys_id = _sys_id;
    SELECT _sys_id INTO _temp_sys_id;
    SELECT 0, NULL, NULL INTO _sys_id, _db, _area;

    SELECT IFNULL(sys_id, 0), IF(ftype = 'hub', hub_db_name, src_db_name), nid, area
      FROM _temp_show_node
      WHERE sys_id > _temp_sys_id AND ftype = 'hub' AND hub_db_name IS NOT NULL
      ORDER BY sys_id ASC LIMIT 1
      INTO _sys_id, _db, _nid, _area;

  END WHILE;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node AS
    SELECT * FROM _temp_show_node WHERE
      (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP()) AND
      privilege > 0 ORDER BY
      -- Directories before files at the PAGING level, not just in the UI.
      -- The client always renders folders in a top section, but the paging
      -- here knew nothing about it: with >45 children a subfolder could land
      -- on page 2+ and pop into the list seconds after the files ("subfolder
      -- takes 3-10s to appear"). Ordering folders first guarantees every
      -- directory is in the earliest page(s).
      CASE WHEN ftype IN ('hub', 'folder') THEN 0 ELSE 1 END ASC,
      CASE WHEN LCASE(_sort_by) = 'date' AND LCASE(_order) = 'asc'  THEN ctime    END ASC,
      CASE WHEN LCASE(_sort_by) = 'date' AND LCASE(_order) = 'desc' THEN ctime    END DESC,
      -- mtime = publish_time (last modification). The column is NOT NULL
      -- DEFAULT 0, so the "missing" sentinel is 0, not NULL — NULLIF maps it
      -- to the creation time instead of pinning never-published rows to the
      -- epoch end of the list.
      CASE WHEN LCASE(_sort_by) = 'mtime' AND LCASE(_order) = 'asc'  THEN IFNULL(NULLIF(mtime, 0), ctime) END ASC,
      CASE WHEN LCASE(_sort_by) = 'mtime' AND LCASE(_order) = 'desc' THEN IFNULL(NULLIF(mtime, 0), ctime) END DESC,
      CASE WHEN LCASE(_sort_by) = 'name' AND LCASE(_order) = 'asc'  THEN filename END ASC,
      CASE WHEN LCASE(_sort_by) = 'name' AND LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort_by) = 'rank' AND LCASE(_order) = 'asc'  THEN rank     END ASC,
      CASE WHEN LCASE(_sort_by) = 'rank' AND LCASE(_order) = 'desc' THEN rank     END DESC,
      CASE WHEN LCASE(_sort_by) = 'size' AND LCASE(_order) = 'asc'  THEN filesize END ASC,
      CASE WHEN LCASE(_sort_by) = 'size' AND LCASE(_order) = 'desc' THEN filesize END DESC,
      -- Deterministic tiebreaker: every sort key above allows large tie
      -- groups (mtime is whole seconds, rank defaults to 0), and each page
      -- is a separate proc call — without a total order, rows inside a tie
      -- group can swap pages between fetches, duplicating or dropping tiles.
      nid ASC
    LIMIT _offset, _range;

  ALTER TABLE _show_node ADD hubs        MEDIUMTEXT;
  ALTER TABLE _show_node ADD nodes       MEDIUMTEXT;
  ALTER TABLE _show_node ADD areas       MEDIUMTEXT;
  ALTER TABLE _show_node ADD actual_home_id VARCHAR(16);

  DROP TABLE IF EXISTS _node_tree;
  CREATE TEMPORARY TABLE _node_tree (
    `seq`        INT NOT NULL AUTO_INCREMENT,
    `heritage_id` VARCHAR(16) CHARACTER SET ascii,
    `id`         VARCHAR(16) CHARACTER SET ascii,
    `parent_id`  VARCHAR(16) CHARACTER SET ascii,
    `category`   VARCHAR(16),
    `areas`      MEDIUMTEXT,
    `new_file`   INT DEFAULT 0,
    PRIMARY KEY `seq`(`seq`)
  );

  INSERT INTO _node_tree (heritage_id, id, parent_id, category)
  WITH RECURSIVE mytree AS
  (
    SELECT mm.id heritage_id, mm.id, mm.parent_id, mm.category
    FROM media mm INNER JOIN _show_node s ON mm.id=s.nid WHERE mm.category IN ('folder', 'hub')
    UNION ALL
    SELECT t.heritage_id, m.id, m.parent_id, m.category
    FROM media AS m JOIN mytree AS t ON m.parent_id = t.id AND
      t.category IN ('folder', 'hub')
  ) SELECT heritage_id, id, parent_id, category FROM mytree;

  SELECT MAX(seq) FROM _node_tree INTO _lvl;
  SELECT id, heritage_id, category FROM _node_tree WHERE seq = _lvl
    INTO _tempid, _heritage_id, _category;

  WHILE (_lvl >= 1 AND _tempid IS NOT NULL) DO
    IF _category = 'hub' THEN
      SELECT db_name, home_id, area FROM yp.entity WHERE id = _tempid
        INTO _hub_db_name, @actual_home_id, @area;
      IF (_hub_db_name IS NOT NULL) THEN
        UPDATE _show_node  SET actual_home_id = @actual_home_id WHERE nid = _tempid;
        UPDATE _node_tree SET areas = @area WHERE id = _tempid;
      END IF;
    END IF;

    SELECT _lvl - 1 INTO _lvl;
    SELECT NULL, NULL INTO _tempid, _category;
    SELECT id, heritage_id, category FROM _node_tree WHERE seq = _lvl
      INTO _tempid, _heritage_id, _category;
  END WHILE;

  -- Initialize folder new_file to 0
  UPDATE _node_tree t
    SET t.new_file = 0
    WHERE t.category <> 'hub' AND t.category != 'root';

  -- Aggregate new_file counts from both child folders and direct files
  UPDATE _show_node t
  INNER JOIN (
    SELECT
      heritage_id,
      SUM(new_file) AS folder_new_file,
      GROUP_CONCAT(DISTINCT CASE WHEN id <> heritage_id THEN id ELSE NULL END) nodes,
      GROUP_CONCAT(DISTINCT CASE WHEN category = 'hub' AND id <> heritage_id THEN id ELSE NULL END) hubs,
      GROUP_CONCAT(DISTINCT CASE WHEN category = 'hub' AND id <> heritage_id THEN areas ELSE NULL END) areas
    FROM _node_tree
    GROUP BY heritage_id
  ) h ON t.nid = h.heritage_id
  LEFT JOIN (
    SELECT
      parent_id,
      SUM(new_file) AS file_new_file
    FROM _temp_show_node
    WHERE ftype NOT IN ('folder', 'hub')
    GROUP BY parent_id
  ) f ON t.nid = f.parent_id
  SET
    t.new_file = IFNULL(h.folder_new_file, 0) + IFNULL(f.file_new_file, 0),
    t.nodes    = h.nodes,
    t.areas    = h.areas,
    t.hubs     = h.hubs;

  SELECT
    nid,
    pid,
    parent_id,
    REGEXP_REPLACE(filepath, '/+', '/') filepath,
    REGEXP_REPLACE(ownpath,  '/+', '/') ownpath,
    holder_id,
    home_id,
    fc.capability capability,
    src_db_name,
    hub_db_name,
    areas,
    accessibility,
    owner_id,
    status,
    filename,
    hub_id,
    IFNULL(area, _hub_area) area,
    filesize,
    vhost,
    isalink,
    caption,
    ext,
    metadata,
    view_count,
    geometry,
    ctime,
    mtime,
    COALESCE(m.ftype, fc.category) ftype,
    COALESCE(m.ftype, fc.category) filetype,
    COALESCE(m.mimetype, fc.mimetype) mimetype,
    JSON_VALUE(metadata, "$.md5Hash") AS md5Hash,
    new_file,
    page,
    rank,
    privilege,
    expiry_time,
    m.sys_id sys_id,
    hubs,
    nodes,
    IFNULL(actual_home_id, _home_id) actual_home_id,
    flag_expiry dmz_expiry
  FROM _show_node m
    LEFT JOIN yp.filecap fc ON m.ext=fc.extension
  ORDER BY
    -- Keep the page-level folder-first contract on the final output too.
    CASE WHEN m.ftype IN ('hub', 'folder') THEN 0 ELSE 1 END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' AND LCASE(_order) = 'asc'  THEN ctime    END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' AND LCASE(_order) = 'desc' THEN ctime    END DESC,
    CASE WHEN LCASE(_sort_by) = 'mtime' AND LCASE(_order) = 'asc'  THEN IFNULL(NULLIF(m.mtime, 0), ctime) END ASC,
    CASE WHEN LCASE(_sort_by) = 'mtime' AND LCASE(_order) = 'desc' THEN IFNULL(NULLIF(m.mtime, 0), ctime) END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' AND LCASE(_order) = 'asc'  THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' AND LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'rank' AND LCASE(_order) = 'asc'  THEN rank     END ASC,
    CASE WHEN LCASE(_sort_by) = 'rank' AND LCASE(_order) = 'desc' THEN rank     END DESC,
    CASE WHEN LCASE(_sort_by) = 'size' AND LCASE(_order) = 'asc'  THEN filesize END ASC,
    CASE WHEN LCASE(_sort_by) = 'size' AND LCASE(_order) = 'desc' THEN filesize END DESC,
    m.nid ASC;

  DROP TABLE IF EXISTS _temp_show_node;
  DROP TABLE IF EXISTS _show_node;
  DROP TABLE IF EXISTS _node_tree;
  DROP TABLE IF EXISTS _temp_latest_events;

END $

DELIMITER ;