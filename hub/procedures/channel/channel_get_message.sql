DELIMITER $

-- =========================================================
-- channel_get_message
--
-- One workspace or folder chat message by id, for the mobile push worker to
-- quote in a banner at delivery time. Mirrors `p2p_get_message` in the
-- drumate schema: the push queue carries only identifiers, so the text is
-- read here, once, when the notification is composed. A trashed message is
-- not returned, so a deleted message is never quoted after the fact.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_get_message`$
CREATE PROCEDURE `channel_get_message`(
  IN _message_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT message_id, author_id, message, thread_id, attachment
  FROM channel
  WHERE message_id = _message_id AND status != 'trashed';
END $

DELIMITER ;
