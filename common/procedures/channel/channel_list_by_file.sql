DELIMITER $
DROP PROCEDURE IF EXISTS `channel_list_by_file`$
CREATE PROCEDURE `channel_list_by_file`(
  IN _file_nid VARCHAR(16)
)
BEGIN
  -- attachment column stores a JSON array of file nids e.g. ["abc123","def456"]
  -- JSON_SEARCH returns non-NULL path if _file_nid exists in the array
  SELECT
    sys_id,
    author_id,
    message,
    message_id,
    thread_id,
    attachment,
    is_forward,
    mention_ids,
    status,
    ctime,
    metadata
  FROM channel
  WHERE status = 'active'
    AND attachment IS NOT NULL
    AND JSON_SEARCH(attachment, 'one', _file_nid) IS NOT NULL
  ORDER BY ctime DESC;
END$
DELIMITER ;