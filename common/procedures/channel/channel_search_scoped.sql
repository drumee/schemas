DELIMITER $
DROP PROCEDURE IF EXISTS `channel_search_scoped`$
CREATE PROCEDURE `channel_search_scoped`(
  IN _uid VARCHAR(16),
  IN _pattern MEDIUMTEXT,
  IN _file_thread_id VARCHAR(16)
)
BEGIN
  DECLARE _like MEDIUMTEXT CHARACTER SET utf8mb4;
  -- Full-text-ish (LIKE) search over the current hub's channel messages, scoped
  -- to ONE conversation:
  --   _file_thread_id NULL/'' -> the workspace/folder team chat (file_thread_id IS NULL)
  --   _file_thread_id set      -> that file thread's child messages (file_thread_id = _file_thread_id)
  -- A message matches on its text OR on the filename of one of its attachments
  -- (active media rows of THIS hub; attachment entries are {nid,hub_id} objects
  -- or legacy bare nid strings). match_filename names the first matching
  -- attachment, NULL for a text-only hit, so the result row can show why it
  -- matched. The pattern is literal: \ % _ are escaped before LIKE.
  -- Excludes messages the caller deleted for themselves (delete_channel), so the
  -- result set matches what the user actually sees in the conversation.
  -- Both LIKEs pin utf8mb4_general_ci: a routine's variables take the database
  -- default collation (uca1400 on newer hubs), which clashes with the
  -- general_ci columns (ERROR 1267). nid/bare are ascii like media.id, or the
  -- join cannot use media's id index and scans media per attachment.
  -- hub_id is tagged by the service layer. preview capped at 150 chars;
  -- newest first; capped at 45 rows.
  SET _like = CONCAT('%',
    REPLACE(REPLACE(REPLACE(_pattern, '\\', '\\\\'), '%', '\\%'), '_', '\\_'),
    '%');
  SELECT
    s.result_type, s.id, s.message_id, s.author_id, s.ctime, s.preview,
    s.match_filename, s.firstname, s.lastname, s.fullname
  FROM (
    SELECT
      'message' AS result_type,
      c.message_id AS id,
      c.message_id,
      c.author_id,
      c.ctime,
      c.message,
      SUBSTRING(c.message, 1, 150) AS preview,
      (
        SELECT m.user_filename
        FROM JSON_TABLE(
          IF(JSON_VALID(c.attachment), c.attachment, '[]'),
          '$[*]' COLUMNS (
            idx FOR ORDINALITY,
            nid VARCHAR(16) CHARACTER SET ascii PATH '$.nid',
            bare VARCHAR(16) CHARACTER SET ascii PATH '$'
          )
        ) j
        JOIN media m ON m.id = COALESCE(j.nid, j.bare) AND m.status = 'active'
        WHERE m.user_filename LIKE _like COLLATE utf8mb4_general_ci
        ORDER BY j.idx
        LIMIT 1
      ) AS match_filename,
      COALESCE(d.firstname, du.name, '') firstname,
      COALESCE(d.lastname, '') lastname,
      COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') fullname
    FROM channel c
    LEFT JOIN yp.drumate d  ON c.author_id = d.id
    LEFT JOIN yp.dmz_user du ON c.author_id = du.id
    WHERE c.status = 'active'
      AND NOT EXISTS (
        SELECT 1 FROM delete_channel dc
        WHERE dc.uid = _uid AND dc.ref_sys_id = c.sys_id
      )
      AND (
        ( (_file_thread_id IS NULL OR _file_thread_id = '') AND c.file_thread_id IS NULL )
        OR
        ( _file_thread_id IS NOT NULL AND _file_thread_id <> '' AND c.file_thread_id = _file_thread_id )
      )
  ) s
  WHERE s.message LIKE _like COLLATE utf8mb4_general_ci
     OR s.match_filename IS NOT NULL
  ORDER BY s.ctime DESC
  LIMIT 45;
END $
DELIMITER ;
