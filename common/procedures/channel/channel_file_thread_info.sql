DELIMITER $

-- =========================================================
-- channel_file_thread_info
-- Lookup a file chat thread by _file_nid OR _file_thread_id (root_message_id).
-- Always returns current file metadata (hydrated from media), so the UI can
-- render the file chat header / card even before a thread exists.
-- exists_thread = 1 only when an active thread row is present.
-- NOTE: permission to read the file is validated by the service
-- (mfs_access_node); the proc only returns data.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_info`$
CREATE PROCEDURE `channel_file_thread_info`(
  IN _uid VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _file_thread_id VARCHAR(16)
)
BEGIN
  IF _file_nid IS NOT NULL AND _file_nid <> '' THEN
    SELECT
      CASE WHEN ft.sys_id IS NOT NULL THEN 1 ELSE 0 END AS exists_thread,
      m.id AS file_nid,
      m.parent_id AS folder_nid,
      ft.root_message_id AS file_thread_id,
      ft.created_by,
      ft.last_message_id,
      ft.reply_count,
      ft.mtime,
      ft.ctime,
      m.user_filename,
      m.extension,
      m.category,
      m.status AS media_status,
      m.file_path,
      cd.firstname AS created_firstname,
      cd.lastname AS created_lastname,
      COALESCE(CONCAT(cd.firstname, ' ', cd.lastname), cd.firstname, du.name, '') AS created_fullname
    FROM media m
    LEFT JOIN file_thread ft ON ft.file_nid = m.id AND ft.status = 'active'
    LEFT JOIN yp.drumate cd ON cd.id = ft.created_by
    LEFT JOIN yp.dmz_user du ON du.id = ft.created_by
    WHERE m.id = _file_nid;
  ELSE
    SELECT
      CASE WHEN ft.sys_id IS NOT NULL THEN 1 ELSE 0 END AS exists_thread,
      ft.file_nid,
      ft.folder_nid,
      ft.root_message_id AS file_thread_id,
      ft.created_by,
      ft.last_message_id,
      ft.reply_count,
      ft.mtime,
      ft.ctime,
      m.user_filename,
      m.extension,
      m.category,
      m.status AS media_status,
      m.file_path,
      cd.firstname AS created_firstname,
      cd.lastname AS created_lastname,
      COALESCE(CONCAT(cd.firstname, ' ', cd.lastname), cd.firstname, du.name, '') AS created_fullname
    FROM file_thread ft
    LEFT JOIN media m ON m.id = ft.file_nid
    LEFT JOIN yp.drumate cd ON cd.id = ft.created_by
    LEFT JOIN yp.dmz_user du ON du.id = ft.created_by
    WHERE ft.root_message_id = _file_thread_id AND ft.status = 'active';
  END IF;
END $

DELIMITER ;
