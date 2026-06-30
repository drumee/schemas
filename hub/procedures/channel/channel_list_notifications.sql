DELIMITER $
DROP PROCEDURE IF EXISTS `channel_list_notifications`$
CREATE PROCEDURE `channel_list_notifications`(
  IN _uid VARCHAR(16),
  IN _type VARCHAR(10),
  IN _unread_only TINYINT(1),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _offset bigint;
  DECLARE _range bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT
    c.sys_id,
    c.author_id,
    c.message,
    c.message_id,
    c.thread_id,
    c.is_forward,
    c.mention_ids,
    c.attachment,
    CASE WHEN LTRIM(RTRIM(c.attachment))='' OR c.attachment IS NULL THEN 0 ELSE 1 END is_attachment,
    c.ctime,
    -- Folder a message was posted in for folder-scoped team chat (NULL for
    -- hub-level messages). Lets the activity item deep-link a mention to the
    -- originating folder's Chat tab instead of the hub root. Additive only.
    JSON_UNQUOTE(JSON_EXTRACT(c.metadata, '$._scope_nid')) AS scope_nid,
    COALESCE(d.firstname, du.name, '') firstname,
    COALESCE(d.lastname, '') lastname,
    COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') fullname,
    CASE WHEN JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_read
  FROM channel c
  LEFT JOIN yp.drumate d ON c.author_id = d.id
  LEFT JOIN yp.dmz_user du ON c.author_id = du.id
  WHERE c.status = 'active'
    AND c.author_id != _uid
    -- Show messages the user was delivered OR has actually seen. A member who
    -- joined after a message was posted (or a dmz_user not in yp.drumate) never
    -- gets _delivered_ from channel_post_message's all-members cursor, yet can
    -- still read the message (channel_read_messages stamps _seen_ ungated). The
    -- old _delivered_-only gate then hid such read messages in BOTH unread and
    -- all modes, so a recently-read mention/share never reappeared with the
    -- Unread toggle OFF. _seen_ is per-user, so this stays correctly scoped.
    AND (
      JSON_EXISTS(c.metadata, CONCAT("$._delivered_.", _uid))= 1
      OR JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _uid))= 1
    )
    AND NOT EXISTS(SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id)
    AND (
      _type = 'all'
      OR (_type = 'mention' AND JSON_SEARCH(c.mention_ids, 'one', _uid) IS NOT NULL)
      OR (_type = 'share' AND (
        c.is_forward = 1
        OR (c.attachment IS NOT NULL AND LTRIM(RTRIM(c.attachment)) != '' AND c.attachment != 'null')
      ))
    )
    AND (_unread_only = 0 OR JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _uid))= 0)
  ORDER BY c.sys_id DESC
  LIMIT _offset, _range;
END$
DELIMITER ;