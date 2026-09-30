DELIMITER $

-- =========================================================
-- channel_topic_list
-- A folder's active topics, oldest first, with the caller's unread: other
-- people's active messages of that topic after the caller's cursor.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_topic_list`$
CREATE PROCEDURE `channel_topic_list`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _folder_nid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT t.id, t.folder_nid, t.name, t.emoji, t.created_by, t.ctime,
    (SELECT COUNT(*) FROM channel c
      WHERE c.status = 'active' AND c.file_thread_id IS NULL
        AND JSON_VALUE(c.metadata, '$._topic_id') = t.id
        AND c.author_id <> _uid
        AND c.sys_id > IFNULL((SELECT r.ref_sys_id FROM channel_topic_read r
                                WHERE r.uid = _uid AND r.topic_id = t.id), 0)) AS unread
  FROM channel_topic t
  WHERE t.folder_nid = _folder_nid AND t.status = 'active'
  ORDER BY t.sys_id ASC;
END$

DELIMITER ;
