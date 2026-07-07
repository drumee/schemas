DELIMITER $

-- =========================================================
-- channel_export_file_thread_list
-- Hub-wide list of active file threads with resolved filename.
-- Used by channel.export_scope to enumerate all file threads
-- the user may include in an export. Single-hub DB context.
-- No pagination — export scope UI renders the full list once.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_file_thread_list`$
CREATE PROCEDURE `channel_export_file_thread_list`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT
    ft.root_message_id AS file_thread_id,
    ft.file_nid,
    m.user_filename    AS filename,
    ft.reply_count
  FROM file_thread ft
  INNER JOIN media m ON m.id = ft.file_nid
  WHERE ft.status = 'active'
  ORDER BY ft.mtime DESC;
END $

DELIMITER ;
