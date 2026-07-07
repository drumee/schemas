DELIMITER $

-- =========================================================
-- channel_file_thread_list_by_folder
-- Existing active file threads for files that are CURRENT direct children of
-- _folder_nid. Folder membership follows media.parent_id (source of truth), NOT
-- file_thread.folder_nid (creation context). A moved file therefore surfaces
-- only under its current parent. Files without a thread never appear here.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_list_by_folder`$
CREATE PROCEDURE `channel_file_thread_list_by_folder`(
  IN _uid VARCHAR(16),
  IN _folder_nid VARCHAR(16),
  IN _order VARCHAR(20),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _dir VARCHAR(4) DEFAULT 'DESC';
  CALL pageToLimits(_page, _offset, _range);
  IF _order = 'asc' THEN
    SET _dir = 'ASC';
  END IF;

  SET @sql = CONCAT(
    'SELECT',
    '   ft.file_nid,',
    '   ft.root_message_id AS file_thread_id,',
    '   ft.folder_nid AS created_folder_nid,',
    '   m.parent_id AS folder_nid,',
    '   ft.created_by,',
    '   ft.reply_count,',
    '   ft.last_message_id,',
    '   ft.mtime,',
    '   ft.ctime,',
    '   m.user_filename,',
    '   m.extension,',
    '   m.category,',
    '   m.status AS media_status',
    ' FROM file_thread ft',
    ' INNER JOIN media m ON m.id = ft.file_nid',
    ' WHERE ft.status = ''active''',
    '   AND m.parent_id = ''', _folder_nid, '''',
    ' ORDER BY ft.mtime ', _dir,
    ' LIMIT ', _offset, ', ', _range
  );
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END $

DELIMITER ;
