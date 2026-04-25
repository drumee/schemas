DELIMITER $
DROP PROCEDURE IF EXISTS `desk_recent_files`$
CREATE PROCEDURE `desk_recent_files`(
  IN _args JSON
)
BEGIN
  DECLARE _page INT DEFAULT 1;
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _idx_time BIGINT UNSIGNED DEFAULT 0;
  DECLARE _last_change BIGINT UNSIGNED DEFAULT 0;
  DECLARE _ts BIGINT UNSIGNED;

  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;
  CALL yp.pageToLimits(_page, _offset, _range);

  -- Derive current user from DB context (drumate DB is per-user)
  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();
  SELECT UNIX_TIMESTAMP() INTO _ts;

  -- Check if media_index is stale (same logic as desk_search)
  SELECT MAX(timestamp) FROM media_index INTO _idx_time;
  SELECT MAX(timestamp) FROM yp.mfs_changelog
    WHERE hub_id IN (SELECT id FROM yp.entity WHERE owner_id = _uid)
    INTO _last_change;

  IF _idx_time IS NULL OR _idx_time <= _last_change THEN
    CALL desk_build_index(JSON_OBJECT());
  END IF;

  -- Return recent files across all hubs accessible to this user.
  -- Exclude hub nodes (workspaces) — shown separately in the top row.
  -- Exclude __chat__ system folders.
  SELECT
    m.hub_id,
    m.home_id,
    m.actual_home_id,
    m.pid,
    m.nid,
    m.area,
    m.filetype,
    m.ext,
    m.status,
    m.isalink,
    m.privilege,
    m.filesize,
    m.filename,
    m.filepath,
    m.ownpath,
    m.mtime,
    m.ctime,
    v.fqdn AS vhost
  FROM media_index m
  LEFT JOIN yp.vhost v ON v.id = m.hub_id
  WHERE m.status = 'active'
    AND m.filetype != 'hub'
    AND m.filename IS NOT NULL
    AND m.filename != '__chat__'
  ORDER BY m.mtime DESC
  LIMIT _offset, _range;

END $
DELIMITER ;