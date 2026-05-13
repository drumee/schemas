DELIMITER $

-- =========================================================
-- p2p_get_message
-- =========================================================
DROP PROCEDURE IF EXISTS `p2p_get_message`$
CREATE PROCEDURE `p2p_get_message`(
  IN _message_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT message_id, author_id, message, thread_id, attachment
  FROM p2p_channel
  WHERE message_id = _message_id AND status != 'trashed';
END $

DELIMITER ;
