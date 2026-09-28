DELIMITER $

-- =========================================================
-- channel_media_stats
-- Media and link counts for the team chat (file_thread_id IS NULL), as
-- the caller sees it (their per-user deletions excluded). Only
-- attachments that resolve to an ACTIVE node of THIS hub's media table
-- are counted, so the numbers match what channel_media_list can page
-- through.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_media_stats`$
CREATE PROCEDURE `channel_media_stats`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT
    IFNULL(SUM(m.category IN ('image','vector')), 0) AS photos,
    IFNULL(SUM(m.category = 'video'), 0) AS videos,
    IFNULL(SUM(m.category NOT IN ('image','vector','video','folder','hub','root')), 0) AS files,
    (
      SELECT COUNT(*) FROM channel c2
      WHERE c2.status = 'active'
        AND c2.file_thread_id IS NULL
        AND c2.message REGEXP 'https?://'
        AND NOT EXISTS (
          SELECT 1 FROM delete_channel dc
          WHERE dc.uid = _uid AND dc.ref_sys_id = c2.sys_id
        )
    ) AS links
  FROM channel c
  JOIN JSON_TABLE(
    IF(JSON_VALID(c.attachment), c.attachment, '[]'),
    '$[*]' COLUMNS (nid VARCHAR(16) PATH '$.nid')
  ) j
  JOIN media m ON m.id = j.nid AND m.status = 'active'
  WHERE c.status = 'active'
    AND c.file_thread_id IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM delete_channel dc
      WHERE dc.uid = _uid AND dc.ref_sys_id = c.sys_id
    );
END $

DELIMITER ;
