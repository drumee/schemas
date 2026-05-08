DELIMITER $

DROP PROCEDURE IF EXISTS `file_version_list`$
CREATE PROCEDURE `file_version_list`(
  IN _hub_id VARCHAR(16),
  IN _search VARCHAR(255),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SELECT
    m.id AS nid,
    m.user_filename AS filename,
    m.file_path,
    m.filesize,
    m.extension AS ext,
    m.category,
    m.mimetype,
    m.parent_id,
    pm.user_filename AS folder_name,
    -- yp.entity.ident is often NULL on freshly-created hubs; fall back
    -- through yp.hub.name, then yp.hub.hubname, mirroring the chain used
    -- by yp.member_list_workspaces.
    IFNULL(IFNULL(e.ident, h.name), h.hubname) AS workspace_name,
    m.upload_time AS ctime,
    m.publish_time AS mtime,
    COUNT(fv.id) AS version_count
  FROM media m
  LEFT JOIN media pm ON pm.id = m.parent_id
  LEFT JOIN yp.entity e ON e.id = _hub_id
  LEFT JOIN yp.hub    h ON h.id = _hub_id
  LEFT JOIN file_version fv ON fv.nid = m.id
  WHERE m.status NOT IN ('hidden', 'deleted')
    AND m.category NOT IN ('folder', 'hub', 'root')
    AND (
      _search = '' OR _search IS NULL
      OR m.user_filename LIKE CONCAT('%', _search, '%')
    )
  GROUP BY m.id, m.user_filename, m.file_path, m.filesize,
           m.extension, m.category, m.mimetype, m.parent_id,
           pm.user_filename, e.ident, m.upload_time, m.publish_time
  HAVING version_count > 0
  ORDER BY version_count DESC, m.publish_time DESC
  LIMIT _offset, _range;
END$

DELIMITER ;