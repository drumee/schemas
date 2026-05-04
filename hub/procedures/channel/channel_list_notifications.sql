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
    COALESCE(d.firstname, du.name, '') firstname,
    COALESCE(d.lastname, '') lastname,
    COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') fullname,
    CASE WHEN JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_read
  FROM channel c
  LEFT JOIN yp.drumate d ON c.author_id = d.id
  LEFT JOIN yp.dmz_user du ON c.author_id = du.id
  WHERE c.status = 'active'
    AND c.author_id != _uid
    AND JSON_EXISTS(c.metadata, CONCAT("$._delivered_.", _uid))= 1
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