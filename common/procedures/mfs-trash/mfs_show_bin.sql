DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_show_bin`$
CREATE PROCEDURE `mfs_show_bin`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _expiry_days INT DEFAULT 30;

  CALL pageToLimits(_page, _offset, _range);

  -- Get expiry config; fallback to 30 if table is empty
  SELECT IFNULL(expiry_days, 30) INTO _expiry_days
    FROM yp.trash_expiry_config LIMIT 1;

  SET @_expiry_days = _expiry_days;

  -- Get Current User ID
  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  DROP TABLE IF EXISTS `_hubs`;
  CREATE TEMPORARY TABLE `_hubs` (
    hub_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    db_name VARCHAR(60) CHARACTER SET ascii DEFAULT NULL,
    home_dir VARCHAR(300) CHARACTER SET ascii DEFAULT NULL,
    is_checked INT DEFAULT 0
  );

  DROP TABLE IF EXISTS _bin_media;
  CREATE TEMPORARY TABLE _bin_media AS
    SELECT
      m.id AS nid,
      m.parent_id AS pid,
      m.parent_id AS parent_id,
      _home_id AS home_id,
      ff.capability,
      me.id AS owner_id,
      me.id AS hub_id,
      m.status AS status,
      m.user_filename AS filename,
      m.filesize AS filesize,
      yp.vhost(me.id) AS vhost,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      m.upload_time AS mtime,
      m.publish_time AS ctime,
      m.origin_id AS modifier_id,
      IFNULL(CONCAT_WS(' ', d.firstname, d.lastname), 'System Admin') AS modifier_name,
      CASE WHEN EXISTS (
        SELECT 1 FROM media pm
        WHERE pm.id = m.parent_id AND pm.status = 'active'
      ) THEN 1 ELSE 0 END AS parent_exists,
      CASE WHEN me.status = 'active' THEN 1 ELSE 0 END AS hub_exists,
      GREATEST(0, _expiry_days - DATEDIFF(NOW(), FROM_UNIXTIME(IFNULL(NULLIF(m.trashed_time, 0), UNIX_TIMESTAMP()))))
                                                                        AS days_remaining
    FROM trash_media m
      INNER JOIN yp.entity me ON me.db_name = DATABASE()
      LEFT JOIN yp.filecap ff ON m.extension = ff.extension
      LEFT JOIN yp.drumate d  ON m.origin_id = d.id
    WHERE m.status = 'deleted';

  INSERT INTO _hubs
  SELECT id, db_name, home_dir, 0
  FROM yp.entity
  WHERE id IN (
    SELECT id FROM media m
    INNER JOIN permission p
      ON p.resource_id = m.id AND p.permission >= 15 AND m.status = 'active'
  );

  SELECT hub_id, db_name, home_dir
    FROM _hubs WHERE is_checked = 0 LIMIT 1
    INTO _hub_id, _db_name, _home_dir;

  WHILE _hub_id IS NOT NULL DO

    SET @sql = CONCAT(
      "INSERT INTO _bin_media (",
        "nid, pid, parent_id, home_id, capability, owner_id, hub_id, ",
        "status, filename, filesize, vhost, ext, ftype, filetype, mimetype, ",
        "ctime, mtime, modifier_id, modifier_name, parent_exists, hub_exists, days_remaining) ",
      "SELECT ",
        "m.id AS nid, ",
        "m.parent_id AS pid, ",
        "m.parent_id AS parent_id, ",
        "me.home_id AS home_id, ",
        "ff.capability, ",
        "me.id AS owner_id, ",
        "me.id AS hub_id, ",
        "m.status AS status, ",
        "m.user_filename AS filename, ",
        "m.filesize AS filesize, ",
        "yp.vhost(me.id) AS vhost, ",
        "m.extension AS ext, ",
        "m.category AS ftype, ",
        "m.category AS filetype, ",
        "m.mimetype, ",
        "m.upload_time AS ctime, ",
        "m.publish_time AS mtime, ",
        "m.origin_id AS modifier_id, ",
        "IFNULL(CONCAT_WS(' ', d.firstname, d.lastname), 'System Admin') AS modifier_name, ",
        "CASE WHEN EXISTS (SELECT 1 FROM ", _db_name, ".media pm ",
          "WHERE pm.id = m.parent_id AND pm.status = 'active') THEN 1 ELSE 0 END AS parent_exists, ",
        "CASE WHEN me.status = 'active' THEN 1 ELSE 0 END AS hub_exists, ",
        "GREATEST(0, @_expiry_days - DATEDIFF(NOW(), FROM_UNIXTIME(IFNULL(NULLIF(m.trashed_time, 0), UNIX_TIMESTAMP())))) AS days_remaining ",
      "FROM ", _db_name, ".trash_media m ",
        "INNER JOIN yp.entity me ON me.db_name = ", QUOTE(_db_name), " ",
        "LEFT JOIN yp.filecap ff ON m.extension = ff.extension ",
        "LEFT JOIN yp.drumate d  ON m.origin_id = d.id ",
      "WHERE m.status = 'deleted' ",
        "AND m.owner_id = ", QUOTE(_uid)
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    UPDATE _hubs SET is_checked = 1 WHERE hub_id = _hub_id;
    SELECT NULL, NULL, NULL INTO _hub_id, _db_name, _home_dir;
    SELECT hub_id, db_name, home_dir
      FROM _hubs WHERE is_checked = 0 LIMIT 1
      INTO _hub_id, _db_name, _home_dir;

  END WHILE;

  -- Total storage occupied by all trash items (across all pages)
  SELECT IFNULL(SUM(filesize), 0) INTO @_total_size
    FROM _bin_media WHERE filename != '__trash__';

  IF _offset < 0 THEN
    SELECT *, @_total_size AS total_size
      FROM _bin_media
      WHERE filename != '__trash__'
      ORDER BY ctime DESC;
  ELSE
    SELECT *, _page AS page, @_total_size AS total_size
      FROM _bin_media
      WHERE filename != '__trash__'
      ORDER BY ctime, filename DESC
      LIMIT _offset, _range;
  END IF;

  DROP TABLE IF EXISTS _bin_media;

END $
DELIMITER ;