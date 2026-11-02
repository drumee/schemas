DELIMITER $

-- =========================================================
-- channel_file_thread_list_by_topic
-- channel_file_thread_list_by_folder restricted to one folder chat topic:
-- the threads whose "file.thread" root card carries that topic
-- (channel.topic_id, see channel_file_thread_set_topic). _topic_id
-- 'general' (or NULL / empty) = the threads started outside any topic,
-- every thread from before topics included.
--
-- Same rows, columns and access rules as channel_file_thread_list_by_folder,
-- which stays as is for the callers that list a whole folder.
--
-- Two kinds of thread appear here:
--
--   file present  the file is a CURRENT direct child of _folder_nid. Folder
--                 membership follows media.parent_id (source of truth), NOT
--                 file_thread.folder_nid (creation context), so a file moved
--                 between folders surfaces only under its current parent.
--
--   file away     the file was moved to another workspace. The conversation
--                 stays here and stays readable, so it keeps its place in the
--                 folder it was created in — dropping it would make a team's
--                 discussion vanish because someone moved a file elsewhere.
--                 lineage_state tells the UI to render it frozen.
--
-- lineage_state is NULL for the ordinary case, 'unavailable' while the file is
-- in another workspace, 'orphaned' once it has been deleted for good.
--
-- Files without a thread never appear here.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_list_by_topic`$
CREATE PROCEDURE `channel_file_thread_list_by_topic`(
  IN _uid VARCHAR(16),
  IN _folder_nid VARCHAR(16),
  IN _topic_id VARCHAR(16),
  IN _order VARCHAR(20),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _dir VARCHAR(4) DEFAULT 'DESC';
  DECLARE _hub_id VARCHAR(16) DEFAULT NULL;
  DECLARE _topic_cond TEXT;
  CALL pageToLimits(_page, _offset, _range);
  IF _order = 'asc' THEN
    SET _dir = 'ASC';
  END IF;

  SELECT id INTO _hub_id FROM yp.entity WHERE db_name = DATABASE() LIMIT 1;

  IF _topic_id IS NULL OR _topic_id = '' OR _topic_id = 'general' THEN
    SET _topic_cond = 'rc.topic_id IS NULL';
  ELSE
    SET _topic_cond = CONCAT('rc.topic_id = ', QUOTE(_topic_id));
  END IF;

  -- An away thread is authorised by the folder it hangs in, not by the file:
  -- the file no longer exists in this database, so user_permission has nothing
  -- to answer about. Reading the folder is the right to read the conversations
  -- kept in it.
  SET @sql = CONCAT(
    'SELECT',
    '   ft.file_nid,',
    '   ft.root_message_id AS file_thread_id,',
    '   ft.folder_nid AS created_folder_nid,',
    '   COALESCE(m.parent_id, ft.folder_nid) AS folder_nid,',
    '   ft.created_by,',
    '   ft.reply_count,',
    '   ft.last_message_id,',
    '   ft.mtime,',
    '   ft.ctime,',
    '   COALESCE(m.user_filename, ftl.file_name) AS user_filename,',
    '   m.extension,',
    '   m.category,',
    '   m.status AS media_status,',
    '   ftl.state AS lineage_state,',
    '   COALESCE(',
    '     NULLIF(JSON_VALUE(hh.profile, ''$.name''), ''''),',
    '     NULLIF(TRIM(CONCAT(COALESCE(hd.firstname, ''''), '' '', COALESCE(hd.lastname, ''''))), ''''),',
    '     NULLIF(he.headline, ''''),',
    '     NULLIF(he.ident, '''')',
    '   ) AS holder_hub_name',
    ' FROM file_thread ft',
    ' LEFT JOIN media m ON m.id = ft.file_nid AND m.status = ''active''',
    ' LEFT JOIN channel rc ON rc.message_id = ft.root_message_id',
    ' LEFT JOIN yp.file_thread_lineage ftl',
    '   ON ftl.current_file_nid = ft.file_nid',
    '   AND ftl.current_hub_id = ''', _hub_id, '''',
    ' LEFT JOIN yp.entity he ON he.id = ftl.holder_hub_id',
    ' LEFT JOIN yp.hub hh ON hh.id = ftl.holder_hub_id',
    ' LEFT JOIN yp.drumate hd ON hd.id = ftl.holder_hub_id',
    ' WHERE ft.status = ''active''',
    '   AND ', _topic_cond,
    '   AND (',
    '     (m.id IS NOT NULL',
    '      AND m.parent_id = ''', _folder_nid, '''',
    '      AND (user_permission(''', _uid, ''', m.id) & 2) = 2)',
    '     OR',
    '     (m.id IS NULL',
    '      AND ftl.state IN (''unavailable'',''orphaned'')',
    '      AND ft.folder_nid = ''', _folder_nid, '''',
    '      AND (user_permission(''', _uid, ''', ''', _folder_nid, ''') & 2) = 2)',
    '   )',
    ' ORDER BY ft.mtime ', _dir,
    ' LIMIT ', _offset, ', ', _range
  );
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END $

DELIMITER ;
