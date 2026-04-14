DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_path`$
CREATE PROCEDURE `mfs_get_path`(
  IN _nid VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_area VARCHAR(30);
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _hub_name VARCHAR(5000);
  DECLARE _is_hub TINYINT DEFAULT 0;

  SELECT _utf8mb4'' COLLATE utf8mb4_general_ci INTO @hub_name;
  SELECT _utf8mb4'' COLLATE utf8mb4_general_ci INTO @parent_path;

  SELECT database() INTO _src_db_name;
  SELECT id FROM media WHERE parent_id = '0' INTO _home_id;

  SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
  SELECT h.id, e.area
    FROM yp.hub h
    INNER JOIN yp.entity e ON e.id = h.id
    WHERE e.db_name = _src_db_name
    INTO _root_hub_id, _hub_area;

  SELECT '' INTO _hub_name;
  IF _root_hub_id IS NOT NULL THEN
    SET @s = CONCAT(
      "SELECT user_filename, parent_path ",
      "FROM ", _user_db_name, ".media ",
      "WHERE id = '", _root_hub_id, "' INTO @hub_name, @parent_path"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    IF @hub_name IS NOT NULL AND @hub_name <> '' THEN
      SELECT CONCAT(@parent_path, '/', @hub_name) INTO _hub_name;
      SELECT 1 INTO _is_hub;
    END IF;
  ELSE
    SELECT _uid INTO _root_hub_id;
  END IF;

  DROP TABLE IF EXISTS __media_path;
  CREATE TEMPORARY TABLE __media_path (
    depth INT NOT NULL DEFAULT 0,
    hub_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    home_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    pid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    filename VARCHAR(1024) DEFAULT NULL,
    filepath VARCHAR(4096) DEFAULT NULL,
    ownpath VARCHAR(4096) DEFAULT NULL,
    filetype VARCHAR(16) DEFAULT NULL,
    ext VARCHAR(50) DEFAULT NULL,
    mimetype VARCHAR(255) DEFAULT NULL,
    filesize BIGINT DEFAULT 0,
    metadata JSON DEFAULT NULL,
    ctime INT(11) UNSIGNED DEFAULT NULL,
    mtime INT(11) UNSIGNED DEFAULT NULL,
    hub_db_name VARCHAR(255) DEFAULT NULL,
    accessibility VARCHAR(16) DEFAULT NULL,
    vhost VARCHAR(255) DEFAULT NULL,
    owner_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    status VARCHAR(30) DEFAULT NULL,
    privilege INT DEFAULT 0,
    src_db_name VARCHAR(255) DEFAULT NULL,
    area VARCHAR(30) DEFAULT NULL
  );
  INSERT INTO __media_path (
    depth, hub_id, home_id, nid, pid, filename, filepath, ownpath,
    filetype, ext, mimetype, filesize, metadata, ctime, mtime,
    hub_db_name, accessibility, vhost, owner_id, status, src_db_name, area
  )
  WITH RECURSIVE ancestors AS (
    SELECT
      0 AS depth,
      m.id,
      m.parent_id,
      m.user_filename,
      m.file_path AS filepath,
      IF(m.category = 'hub', '/', m.file_path) AS ownpath,
      m.category,
      m.extension,
      m.mimetype,
      m.filesize,
      m.metadata,
      m.upload_time,
      m.publish_time,
      he.db_name AS hub_db_name,
      COALESCE(he.accessibility, me.accessibility) AS accessibility,
      COALESCE(vv.fqdn, v.fqdn) AS vhost,
      COALESCE(he.id, m.owner_id) AS owner_id,
      COALESCE(he.status, m.status) AS `status`,
      IFNULL(he.area, _hub_area) AS area
    FROM media m
    INNER JOIN yp.entity me ON me.db_name = database()
    LEFT JOIN yp.vhost v ON v.id = me.id
    LEFT JOIN yp.entity he ON m.id = he.id AND m.category = 'hub'
    LEFT JOIN yp.vhost vv ON vv.id = m.id
    WHERE m.id = _nid

    UNION ALL

    SELECT
      a.depth + 1,
      m.id,
      m.parent_id,
      m.user_filename,
      m.file_path AS filepath,
      IF(m.category = 'hub', '/', m.file_path) AS ownpath,
      m.category,
      m.extension,
      m.mimetype,
      m.filesize,
      m.metadata,
      m.upload_time,
      m.publish_time,
      he.db_name AS hub_db_name,
      COALESCE(he.accessibility, me.accessibility) AS accessibility,
      COALESCE(vv.fqdn, v.fqdn) AS vhost,
      COALESCE(he.id, m.owner_id) AS owner_id,
      COALESCE(he.status, m.status) AS `status`,
      IFNULL(he.area, _hub_area) AS area
    FROM media m
    INNER JOIN ancestors a ON m.id = a.parent_id AND a.parent_id != '0'
    INNER JOIN yp.entity me ON me.db_name = database()
    LEFT JOIN yp.vhost v ON v.id = me.id
    LEFT JOIN yp.entity he ON m.id = he.id AND m.category = 'hub'
    LEFT JOIN yp.vhost vv ON vv.id = m.id
  )
  SELECT
    depth,
    _root_hub_id,
    _home_id,
    id,
    parent_id,
    user_filename,
    filepath,
    ownpath,
    category,
    extension,
    mimetype,
    filesize,
    metadata,
    upload_time,
    publish_time,
    hub_db_name,
    accessibility,
    vhost,
    owner_id,
    `status`,
    _src_db_name,
    area
  FROM ancestors;

  -- Compute privilege for each node in path (within current hub context)
  UPDATE __media_path SET privilege = user_permission(_uid, nid);

  SELECT
    hub_id,
    home_id,
    nid,
    pid,
    filename,
    @hub_name hub_name,
    filepath,
    REGEXP_REPLACE(ownpath, '/+', '/') AS ownpath,
    IF(_is_hub AND depth=1, 'folder', filetype) filetype,
    ext,
    mimetype,
    filesize,
    metadata,
    ctime,
    mtime,
    hub_db_name,
    accessibility,
    vhost,
    owner_id,
    status,
    privilege,
    src_db_name,
    area
  FROM __media_path
  ORDER BY depth DESC;

  DROP TABLE IF EXISTS __media_path;
END$

DELIMITER ;