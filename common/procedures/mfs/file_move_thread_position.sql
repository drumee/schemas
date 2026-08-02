DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_thread_position`$
CREATE PROCEDURE `file_move_thread_position`(
  IN _file_nid VARCHAR(16),
  IN _thread_id VARCHAR(16)
)
BEGIN
  SELECT
    ft.file_nid,
    ft.folder_nid,
    ft.root_message_id AS file_thread_id,
    ft.created_by,
    ft.reply_count,
    ft.ctime,
    ft.mtime,
    m.status AS media_status,
    (SELECT COUNT(*) FROM channel c
      WHERE c.message_id = ft.root_message_id
        AND JSON_VALID(c.metadata) = 1
        AND JSON_VALUE(c.metadata, '$._file_nid') = ft.file_nid) AS root_identity_count,
    (SELECT COUNT(*) FROM channel c
      WHERE c.file_thread_id = ft.root_message_id
        AND JSON_VALID(c.metadata) = 1
        AND COALESCE(JSON_VALUE(c.metadata, '$._file_nid'), '') <> ft.file_nid)
      AS stale_child_identity_count
  FROM file_thread ft
  LEFT JOIN media m ON m.id = ft.file_nid
  WHERE ft.status = 'active'
    AND (_file_nid IS NULL OR ft.file_nid = _file_nid)
    AND (_thread_id IS NULL OR ft.root_message_id = _thread_id)
  LIMIT 1;
END $

DELIMITER ;
