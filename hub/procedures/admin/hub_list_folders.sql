DELIMITER $

DROP PROCEDURE IF EXISTS `hub_list_folders`$
CREATE PROCEDURE `hub_list_folders`(
  IN _node_id VARCHAR(16) CHARACTER SET ascii,
  IN _page    TINYINT(4),
  IN _query   VARCHAR(255) CHARACTER SET utf8mb4
)
BEGIN
  -- Lists folder/hub children of a node for the admin Permissions tab
  -- workspace drill-down. mfs_show_node_by works in raw SQL but its
  -- internal UPDATE/ALTER traffic confuses the @drumee mariadb wrapper's
  -- multi-resultset handling and returns an empty array to the caller.
  -- This SP yields a single, clean SELECT — same WHERE filters
  -- (categories + path-prefix exclusion + status) so the visual surface
  -- matches.
  --
  -- _node_id NULL means "list children of the hub root".
  -- _query (when non-empty) searches user_filename across the whole hub
  -- instead of scoping to _node_id's direct children.

  DECLARE _range   BIGINT;
  DECLARE _offset  BIGINT;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _has_q   TINYINT(1) DEFAULT 0;
  DECLARE _like    VARCHAR(520) CHARACTER SET utf8mb4;

  CALL pageToLimits(_page, _offset, _range);

  SELECT id FROM media WHERE parent_id = '0' INTO _home_id;

  -- The @drumee mariadb wrapper coerces JS null to the empty string before
  -- sending to the SP, so we must treat '' the same as NULL/'0' here —
  -- otherwise WHERE parent_id = '' matches nothing and the FE gets [].
  IF _node_id IS NULL OR _node_id = '0' OR _node_id = '' THEN
    SET _node_id = _home_id;
  END IF;

  IF _query IS NOT NULL AND _query <> '' THEN
    SET _has_q = 1;
    -- Escape LIKE wildcards in the user-supplied query so '%' / '_'
    -- are matched literally; '|' is the ESCAPE char below.
    SET _like = CONCAT(
      '%',
      REPLACE(REPLACE(REPLACE(_query, '|', '||'), '%', '|%'), '_', '|_'),
      '%'
    );
  END IF;

  SELECT
    m.id            AS nid,
    m.id            AS id,
    m.user_filename AS filename,
    m.user_filename AS name,
    m.parent_id     AS parent_id,
    m.category      AS category,
    m.status        AS status,
    m.file_path     AS file_path,
    m.upload_time   AS ctime,
    m.publish_time  AS mtime,
    m.publish_time  AS updated,
    m.filesize      AS filesize,
    m.filesize      AS size,
    m.extension     AS ext,
    m.metadata      AS metadata
  FROM media m
  WHERE (_has_q = 1 OR m.parent_id = _node_id)
    AND (_has_q = 0 OR m.user_filename LIKE _like ESCAPE '|')
    AND m.category IN ('folder', 'hub')
    AND m.status NOT IN ('hidden', 'deleted')
    AND m.file_path NOT REGEXP '^/__(chat|trash|upload)__'
  ORDER BY m.user_filename ASC
  LIMIT _offset, _range;
END$

DELIMITER ;
