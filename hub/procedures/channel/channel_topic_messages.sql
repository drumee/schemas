DELIMITER $

-- =========================================================
-- channel_topic_messages
-- One page of a topic's messages — channel_list_messages restricted to
-- metadata._topic_id, same columns. No read side effect: a topic's read
-- cursor is channel_topic_read (channel_topic_mark_read).
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_topic_messages`$
CREATE PROCEDURE `channel_topic_messages`(
  IN _uid VARCHAR(16),
  IN _topic_id VARCHAR(16) CHARACTER SET ascii,
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _recipient_db VARCHAR(255);
  DECLARE _msg_id VARCHAR(16);
  DECLARE _timestamp int(11) unsigned;
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;
  CALL pageToLimits(_page, _offset, _range);
  -- File-thread child messages never appear in the normal (workspace/folder)
  -- chat list; they have their own list path (channel_file_thread_list_messages).
  SELECT ref_sys_id FROM channel_topic_read WHERE uid = _uid AND topic_id = _topic_id INTO _old_ref_sys_id;
  SELECT
    _page as `page`,
    c.sys_id,
    c.author_id,
    c.message,
    c.message_id,
    c.thread_id,
    c.file_thread_id,
    c.is_forward,
    c.mention_ids,
    c.attachment,
    CASE WHEN LTRIM(RTRIM(c.attachment))='' OR  c.attachment IS NULL THEN 0 ELSE 1 END is_attachment,
    c.status,
    c.ctime,
    c.metadata,
    IFNULL(read_json_object(c.metadata, 'message_type'), 'chat') message_type,
    COALESCE(d.firstname, du.name, '') firstname,
    COALESCE(d.lastname, '') lastname,
    COALESCE(NULLIF(TRIM(CONCAT(IFNULL(d.firstname, ''), ' ', IFNULL(d.lastname, ''))), ''), d.fullname, du.name, '') fullname,
    COALESCE(d.email, du.email) email,
    CASE WHEN _old_ref_sys_id  <  c.sys_id THEN 1 ELSE 0 END is_notify,
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_')
    THEN  1 ELSE 0 END is_seen
  FROM
    (SELECT sys_id FROM channel c
      WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id)
      AND c.file_thread_id IS NULL
      AND c.topic_id = _topic_id
    ORDER BY c.sys_id  DESC LIMIT _offset, _range) s
  INNER JOIN channel c  on c.sys_id = s.sys_id
  LEFT JOIN yp.drumate d ON c.author_id = d.id
  LEFT JOIN yp.dmz_user du ON c.author_id = du.id

  ORDER BY c.sys_id DESC;
END$
DELIMITER ;
