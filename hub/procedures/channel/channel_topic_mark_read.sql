DELIMITER $

-- =========================================================
-- channel_topic_mark_read
-- Advance the caller's read cursor of one topic to its newest message.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_topic_mark_read`$
CREATE PROCEDURE `channel_topic_mark_read`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _topic_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _ref INT(11) UNSIGNED DEFAULT 0;
  SELECT IFNULL(MAX(sys_id), 0) FROM channel
    WHERE JSON_VALUE(metadata, '$._topic_id') = _topic_id INTO _ref;
  INSERT INTO channel_topic_read (uid, topic_id, ref_sys_id, ctime)
    VALUES (_uid, _topic_id, _ref, UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE ref_sys_id = GREATEST(ref_sys_id, VALUES(ref_sys_id)), ctime = VALUES(ctime);
  SELECT _ref AS ref_sys_id;
END$

DELIMITER ;
