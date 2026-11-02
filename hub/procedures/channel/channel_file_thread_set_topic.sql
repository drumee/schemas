DELIMITER $

-- =========================================================
-- channel_file_thread_set_topic
-- Put a new file thread in the folder chat topic it was started from: stamp
-- metadata._topic_id on its "file.thread" root card (channel.topic_id is the
-- virtual column over it), so the card shows in that topic's chat and the
-- thread is listed under that topic (channel_file_thread_list_by_topic).
--
-- Only an untagged root card is touched: a thread keeps the topic it was
-- started in. _topic_id must be a topic of the card's folder (checked by the
-- service before the call).
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_set_topic`$
CREATE PROCEDURE `channel_file_thread_set_topic`(
  IN _root_message_id VARCHAR(16),
  IN _topic_id VARCHAR(16)
)
BEGIN
  UPDATE channel
    SET metadata = JSON_SET(IFNULL(metadata, '{}'), '$._topic_id', _topic_id)
    WHERE message_id = _root_message_id
      AND JSON_VALUE(metadata, '$._file_thread_root') = 1
      AND topic_id IS NULL;
  SELECT ROW_COUNT() AS updated;
END $

DELIMITER ;
