DELIMITER $

-- =========================================================
-- channel_file_thread_list_messages
-- Child messages of one file thread (channel.file_thread_id = _file_thread_id),
-- enriched with the same author/entity/read shape as channel_list_messages.
-- Marks THIS thread's messages seen up to the page boundary on open — scoped
-- to file_thread_id so it never touches sibling folder/workspace read state.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_list_messages`$
CREATE PROCEDURE `channel_file_thread_list_messages`(
  IN _uid VARCHAR(16),
  IN _file_thread_id VARCHAR(16),
  IN _order VARCHAR(20),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _ref_sys_id int(11) unsigned default 0;
  CALL pageToLimits(_page, _offset, _range);

  SELECT sys_id INTO _ref_sys_id FROM (
    SELECT sys_id FROM channel c
    WHERE c.file_thread_id = _file_thread_id
      AND NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid = _uid AND ref_sys_id = c.sys_id)
    ORDER BY c.sys_id DESC LIMIT _offset, _range
  ) a ORDER BY sys_id DESC LIMIT 1;

  IF _ref_sys_id > 0 THEN
    UPDATE channel SET metadata = JSON_SET(metadata, CONCAT('$._seen_.', _uid), UNIX_TIMESTAMP())
    WHERE file_thread_id = _file_thread_id
      AND sys_id <= _ref_sys_id
      AND JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid)) = 0;
  END IF;

  SELECT
    _page AS `page`,
    c.sys_id,
    c.author_id,
    c.message,
    c.message_id,
    c.thread_id,
    c.file_thread_id,
    c.is_forward,
    c.mention_ids,
    c.attachment,
    CASE WHEN LTRIM(RTRIM(c.attachment))='' OR c.attachment IS NULL THEN 0 ELSE 1 END is_attachment,
    c.status,
    c.ctime,
    c.metadata,
    COALESCE(d.firstname, du.name, '') firstname,
    COALESCE(d.lastname, '') lastname,
    COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') fullname,
    CASE WHEN JSON_EXISTS(c.metadata, CONCAT('$._seen_.', _uid)) = 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(c.metadata, '$._seen_') >= JSON_LENGTH(c.metadata, '$._delivered_')
      THEN 1 ELSE 0 END is_seen,
    IFNULL(read_json_object(c.metadata, 'message_type'), 'chat') message_type,
    read_json_object(c.metadata, 'call_status') call_status
  FROM (
    SELECT sys_id FROM channel c
    WHERE c.file_thread_id = _file_thread_id
      AND NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid = _uid AND ref_sys_id = c.sys_id)
    ORDER BY c.sys_id DESC LIMIT _offset, _range
  ) s
  INNER JOIN channel c ON c.sys_id = s.sys_id
  LEFT JOIN yp.drumate d ON c.author_id = d.id
  LEFT JOIN yp.dmz_user du ON c.author_id = du.id
  ORDER BY c.sys_id DESC;
END $

DELIMITER ;
