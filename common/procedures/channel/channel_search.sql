DELIMITER $
DROP PROCEDURE IF EXISTS `channel_search`$
CREATE PROCEDURE `channel_search`(
  IN _pattern MEDIUMTEXT
)
BEGIN
  -- Runs in a specific hub DB context.
  -- hub_id is NOT returned here — the service layer tags each row after calling.
  -- preview is capped at 150 chars to avoid sending full message text over the wire.
  SELECT
    'message' AS result_type,
    message_id AS id,
    message_id,
    thread_id,
    file_thread_id,
    author_id,
    ctime,
    SUBSTRING(message, 1, 150) AS preview
  FROM channel
  WHERE status  = 'active'
    AND message IS NOT NULL
    AND message LIKE CONCAT('%', _pattern, '%')
  ORDER BY ctime DESC
  LIMIT 45;
END $
DELIMITER ;