DELIMITER $
DROP PROCEDURE IF EXISTS `task_search_linkable_files`$
CREATE PROCEDURE `task_search_linkable_files`(
  IN _uid     VARCHAR(16),
  IN _task_id VARCHAR(16),
  IN _pattern VARCHAR(84),
  IN _page    TINYINT(4)
)
BEGIN
  -- Search active media in the current hub the user can read,
  -- excluding files already linked to _task_id (when provided).
  -- Hubs/folders are excluded — only regular files are linkable.
  DECLARE _range  BIGINT;
  DECLARE _offset BIGINT;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    m.id            AS nid,
    m.user_filename AS filename,
    m.extension     AS ext,
    m.category,
    m.filesize,
    m.upload_time   AS mtime,
    IF(m.user_filename = _pattern, 100, 0)
      + IF(m.user_filename LIKE CONCAT('%', _pattern, '%'), 50, 0) AS score
  FROM media m
  WHERE m.status = 'active'
    AND m.category <> 'hub'
    AND m.isalink = 0
    AND m.file_path NOT REGEXP '^/__(chat|trash)__'
    AND user_permission(_uid, m.id) > 0
    AND (_task_id IS NULL OR m.id NOT IN (
          SELECT file_nid FROM task_file WHERE task_id = _task_id
        ))
  HAVING score > 25
  ORDER BY score DESC, m.upload_time DESC
  LIMIT _offset, _range;
END$
DELIMITER ;
