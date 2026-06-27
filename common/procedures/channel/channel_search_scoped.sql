DELIMITER $
DROP PROCEDURE IF EXISTS `channel_search_scoped`$
CREATE PROCEDURE `channel_search_scoped`(
  IN _uid VARCHAR(16),
  IN _pattern MEDIUMTEXT,
  IN _file_thread_id VARCHAR(16)
)
BEGIN
  -- Full-text-ish (LIKE) search over the current hub's channel messages, scoped
  -- to ONE conversation:
  --   _file_thread_id NULL/'' -> the workspace/folder team chat (file_thread_id IS NULL)
  --   _file_thread_id set      -> that file thread's child messages (file_thread_id = _file_thread_id)
  -- Excludes messages the caller deleted for themselves (delete_channel), so the
  -- result set matches what the user actually sees in the conversation. Mirrors
  -- channel_search's projection (+ author name) plus the scope + per-user delete
  -- filter. hub_id is tagged by the service layer. preview capped at 150 chars;
  -- newest first; capped at 45 rows.
  SELECT
    'message' AS result_type,
    c.message_id AS id,
    c.message_id,
    c.author_id,
    c.ctime,
    SUBSTRING(c.message, 1, 150) AS preview,
    COALESCE(d.firstname, du.name, '') firstname,
    COALESCE(d.lastname, '') lastname,
    COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') fullname
  FROM channel c
  LEFT JOIN yp.drumate d  ON c.author_id = d.id
  LEFT JOIN yp.dmz_user du ON c.author_id = du.id
  WHERE c.status = 'active'
    AND c.message IS NOT NULL
    AND c.message LIKE CONCAT('%', _pattern, '%')
    AND NOT EXISTS (
      SELECT 1 FROM delete_channel dc
      WHERE dc.uid = _uid AND dc.ref_sys_id = c.sys_id
    )
    AND (
      ( (_file_thread_id IS NULL OR _file_thread_id = '') AND c.file_thread_id IS NULL )
      OR
      ( _file_thread_id IS NOT NULL AND _file_thread_id <> '' AND c.file_thread_id = _file_thread_id )
    )
  ORDER BY c.ctime DESC
  LIMIT 45;
END $
DELIMITER ;
