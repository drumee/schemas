DELIMITER $

-- =========================================================
-- channel_topic_mark_read
-- Advance the caller's read cursor of one topic to its newest message, and
-- stamp the caller into _seen_ on that topic's messages only (read receipts)
-- — never the hub-wide read_channel cursor or other conversations.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_topic_mark_read`$
CREATE PROCEDURE `channel_topic_mark_read`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _topic_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _ref INT(11) UNSIGNED DEFAULT 0;
  SELECT IFNULL(MAX(sys_id), 0) FROM channel WHERE topic_id = _topic_id INTO _ref;
  -- JSON_SET cannot create the _seen_ parent: merge into it instead.
  UPDATE channel SET metadata = JSON_SET(IFNULL(metadata, '{}'), '$._seen_',
      JSON_MERGE_PATCH(IFNULL(JSON_EXTRACT(metadata, '$._seen_'), '{}'), JSON_OBJECT(_uid, UNIX_TIMESTAMP())))
    WHERE topic_id = _topic_id AND sys_id <= _ref AND file_thread_id IS NULL
      AND JSON_EXISTS(IFNULL(metadata, '{}'), CONCAT('$._seen_.', _uid)) = 0;
  INSERT INTO channel_topic_read (uid, topic_id, ref_sys_id, ctime)
    VALUES (_uid, _topic_id, _ref, UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE ref_sys_id = GREATEST(ref_sys_id, VALUES(ref_sys_id)), ctime = VALUES(ctime);
  SELECT _ref AS ref_sys_id;
END$

DELIMITER ;
