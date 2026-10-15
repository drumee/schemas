DELIMITER $

-- =========================================================
-- channel_media_list
-- One page of the team chat's photos / videos / files (60 per page)
-- or link messages (30 per page), newest first. Same scope and
-- classification as channel_media_stats.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_media_list`$
CREATE PROCEDURE `channel_media_list`(
  IN _uid VARCHAR(16),
  IN _kind VARCHAR(8),
  IN _page INT
)
BEGIN
  DECLARE _size INT DEFAULT 60;
  DECLARE _offset INT DEFAULT 0;

  IF _kind = 'link' THEN
    SET _size = 30;
  END IF;
  SET _offset = (GREATEST(IFNULL(_page, 1), 1) - 1) * _size;

  IF _kind = 'link' THEN
    SELECT
      c.message_id,
      c.ctime,
      SUBSTRING(REGEXP_REPLACE(c.message, '<[^>]*>', ''), 1, 300) AS preview,
      REGEXP_SUBSTR(c.message, 'https?://[^[:space:]<>"'']+') AS url
    FROM channel c
    WHERE c.status = 'active'
      AND c.file_thread_id IS NULL
      AND c.message REGEXP 'https?://'
      AND NOT EXISTS (
        SELECT 1 FROM delete_channel dc
        WHERE dc.uid = _uid AND dc.ref_sys_id = c.sys_id
      )
    ORDER BY c.ctime DESC, c.sys_id DESC
    LIMIT _offset, _size;
  ELSE
    SELECT
      m.id AS nid,
      m.category,
      m.user_filename AS filename,
      m.extension,
      m.filesize,
      JSON_VALUE(m.metadata, '$.duration') AS duration,
      c.ctime,
      c.message_id
    FROM channel c
    JOIN JSON_TABLE(
      IF(JSON_VALID(c.attachment), c.attachment, '[]'),
      '$[*]' COLUMNS (idx FOR ORDINALITY, nid VARCHAR(16) PATH '$.nid')
    ) j
    JOIN media m ON m.id = j.nid AND m.status = 'active'
    WHERE c.status = 'active'
      AND c.file_thread_id IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM delete_channel dc
        WHERE dc.uid = _uid AND dc.ref_sys_id = c.sys_id
      )
      AND CASE _kind
        WHEN 'photo' THEN m.category IN ('image','vector')
        WHEN 'video' THEN m.category = 'video'
        WHEN 'file'  THEN m.category NOT IN ('image','vector','video','folder','hub','root')
        ELSE 0
      END
    ORDER BY c.ctime DESC, c.sys_id DESC, j.idx DESC
    LIMIT _offset, _size;
  END IF;
END $

DELIMITER ;
