DELIMITER $

-- =========================================================
-- channel_export_file_thread_list
-- List active file threads for chat export, restricted to
-- files living inside the folder subtree rooted at _root_nid
-- (current membership follows media.parent_id, matching
-- channel_file_thread_list_by_folder). _root_nid NULL/''/'0'
-- = hub root (whole hub).
-- Also returns the file's current folder (folder_nid +
-- folder_name) so export sections can label threads with
-- their location. Only active files — trashed files keep
-- their thread row but must not appear in the export scope.
-- Used by channel.export_scope and the export gather.
-- No pagination — export scope UI renders the full list once.
-- READ-ONLY.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_file_thread_list`$
CREATE PROCEDURE `channel_export_file_thread_list`(
  IN _uid      VARCHAR(16),
  IN _root_nid VARCHAR(16)
)
BEGIN
  DECLARE _root VARCHAR(16) DEFAULT NULL;

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
  SELECT
    ft.root_message_id AS file_thread_id,
    ft.file_nid,
    m.user_filename    AS filename,
    m.parent_id        AS folder_nid,
    f.user_filename    AS folder_name,
    ft.reply_count
  FROM file_thread ft
  INNER JOIN media m ON m.id = ft.file_nid
  LEFT  JOIN media f ON f.id = m.parent_id
  WHERE ft.status = 'active'
    AND m.status = 'active'
    AND m.parent_id IN (SELECT id FROM subtree)
  ORDER BY ft.mtime DESC;
END $

DELIMITER ;
