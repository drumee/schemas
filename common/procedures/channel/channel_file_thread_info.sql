DELIMITER $

-- =========================================================
-- channel_file_thread_info
-- Lookup a file chat thread by _file_nid OR _file_thread_id (root_message_id).
-- Always returns current file metadata (hydrated from media), so the UI can
-- render the file chat header / card even before a thread exists.
-- exists_thread = 1 only when an active thread row is present.
-- NOTE: permission to read the file is validated by the service
-- (mfs_access_node); the proc only returns data.
--
-- lineage_state / holder_hub_name describe a thread whose file has left this
-- workspace. The thread stays here and stays readable; the file is elsewhere,
-- so the UI shows the info card as read-only and names where the file went.
--   NULL / 'active'  file is here, nothing to say
--   'unavailable'    file moved to holder_hub_name, may still return
--   'orphaned'       file was deleted for good; the thread is now history
-- Left-joined: a thread that never moved has no lineage row, which is the
-- overwhelmingly common case and must not drop it from the result.
--
-- The join goes through file_thread.file_nid, not root_message_id: only
-- (current_hub_id, current_file_nid) is unique in lineage. Thread id is not —
-- a failed move can strand a second row carrying the same thread id and a
-- dead file_nid, and joining on it would let that row decide what the card
-- displays. Matching the file the thread actually points at picks the live
-- row every time.
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
      COALESCE(CONCAT(cd.firstname, ' ', cd.lastname), cd.firstname, du.name, '') AS created_fullname,
      ftl.state AS lineage_state,
      ftl.file_name AS away_file_name,
      COALESCE(
        NULLIF(JSON_VALUE(hh.profile, '$.name'), ''),
        NULLIF(TRIM(CONCAT(COALESCE(hd.firstname, ''), ' ', COALESCE(hd.lastname, ''))), ''),
        NULLIF(he.headline, ''),
        NULLIF(he.ident, '')
      ) AS holder_hub_name
    FROM media m
    LEFT JOIN file_thread ft ON ft.file_nid = m.id AND ft.status = 'active'
    LEFT JOIN yp.drumate cd ON cd.id = ft.created_by
    LEFT JOIN yp.dmz_user du ON du.id = ft.created_by
    LEFT JOIN yp.file_thread_lineage ftl ON ftl.current_file_nid = ft.file_nid
    LEFT JOIN yp.entity he ON he.id = ftl.holder_hub_id
    LEFT JOIN yp.hub hh ON hh.id = ftl.holder_hub_id
    LEFT JOIN yp.drumate hd ON hd.id = ftl.holder_hub_id
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
      COALESCE(CONCAT(cd.firstname, ' ', cd.lastname), cd.firstname, du.name, '') AS created_fullname,
      ftl.state AS lineage_state,
      ftl.file_name AS away_file_name,
      COALESCE(
        NULLIF(JSON_VALUE(hh.profile, '$.name'), ''),
        NULLIF(TRIM(CONCAT(COALESCE(hd.firstname, ''), ' ', COALESCE(hd.lastname, ''))), ''),
        NULLIF(he.headline, ''),
        NULLIF(he.ident, '')
      ) AS holder_hub_name
    FROM file_thread ft
    LEFT JOIN media m ON m.id = ft.file_nid
    LEFT JOIN yp.drumate cd ON cd.id = ft.created_by
    LEFT JOIN yp.dmz_user du ON du.id = ft.created_by
    LEFT JOIN yp.file_thread_lineage ftl ON ftl.current_file_nid = ft.file_nid
    LEFT JOIN yp.entity he ON he.id = ftl.holder_hub_id
    LEFT JOIN yp.hub hh ON hh.id = ftl.holder_hub_id
    LEFT JOIN yp.drumate hd ON hd.id = ftl.holder_hub_id
    WHERE ft.root_message_id = _file_thread_id AND ft.status = 'active';
  END IF;
END $

DELIMITER ;
