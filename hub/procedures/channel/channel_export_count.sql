DELIMITER $

-- =========================================================
-- channel_export_count
-- Fast COUNT of team-chat messages (file_thread_id IS NULL)
-- for the given uid, optional date range, and folder subtree.
-- Used by the 10k guard in channel.export and the message
-- count shown on the export modal's folder card.
-- Date bounds arrive as VARCHAR: the mariadb layer converts a
-- JS null param to '' (empty string), which an INT(11) IN-param
-- rejects under strict SQL mode. Accept text, normalise '' / NULL
-- to a NULL bound (no filter) and CAST numeric strings to epoch.
-- Folder scope mirrors channel_export_messages: only messages
-- whose metadata._scope_nid falls inside the subtree rooted at
-- _root_nid are counted; legacy rows (no _scope_nid) always
-- count. _root_nid NULL/''/'0' = hub root (whole hub).
-- READ-ONLY: no UPDATE / INSERT.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_count`$
CREATE PROCEDURE `channel_export_count`(
  IN _uid        VARCHAR(16),
  IN _root_nid   VARCHAR(16),
  IN _date_start VARCHAR(20),
  IN _date_end   VARCHAR(20)
)
BEGIN
  DECLARE _root VARCHAR(16) DEFAULT NULL;
  DECLARE ds BIGINT DEFAULT NULL;
  DECLARE de BIGINT DEFAULT NULL;
  IF _date_start IS NOT NULL AND _date_start <> '' THEN SET ds = CAST(_date_start AS UNSIGNED); END IF;
  IF _date_end   IS NOT NULL AND _date_end   <> '' THEN SET de = CAST(_date_end   AS UNSIGNED); END IF;

  IF _root_nid IS NOT NULL AND _root_nid <> '' AND _root_nid <> '0' THEN
    SELECT id INTO _root FROM media WHERE id = _root_nid LIMIT 1;
  END IF;
  IF _root IS NULL THEN
    SELECT id INTO _root FROM media WHERE parent_id = '0' LIMIT 1;
  END IF;

  WITH RECURSIVE subtree AS (
    SELECT m.id FROM media m WHERE m.id = _root
    UNION ALL
    SELECT c.id
    FROM media c
    INNER JOIN subtree s ON c.parent_id = s.id
    WHERE c.mimetype = 'folder' AND c.status = 'active'
  )
  SELECT COUNT(*) AS message_count
  FROM channel c
  WHERE
    c.file_thread_id IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM delete_channel
      WHERE uid = _uid AND ref_sys_id = c.sys_id
    )
    AND (ds IS NULL OR c.ctime >= ds)
    AND (de IS NULL OR c.ctime <= de)
    AND (
      read_json_object(c.metadata, '_scope_nid') = ''
      OR read_json_object(c.metadata, '_scope_nid') IN (SELECT id FROM subtree)
    );
END $

DELIMITER ;
